import { mapAsset } from 'src/dtos/asset-response.dto';
import { ViewService } from 'src/services/view.service';
import { AssetFactory } from 'test/factories/asset.factory';
import { authStub } from 'test/fixtures/auth.stub';
import { getForAsset } from 'test/mappers';
import { newTestService, ServiceMocks } from 'test/utils';

describe(ViewService.name, () => {
  let sut: ViewService;
  let mocks: ServiceMocks;

  beforeEach(() => {
    ({ sut, mocks } = newTestService(ViewService));
  });

  it('should work', () => {
    expect(sut).toBeDefined();
  });

  describe('getUniqueOriginalPaths', () => {
    it('should return unique original paths', async () => {
      const mockPaths = ['path1', 'path2', 'path3'];
      mocks.view.getUniqueOriginalPaths.mockResolvedValue(mockPaths);

      const result = await sut.getUniqueOriginalPaths(authStub.admin, { externalOnly: true });

      expect(result).toEqual(mockPaths);
      expect(mocks.view.getUniqueOriginalPaths).toHaveBeenCalledWith(authStub.admin.user.id, { externalOnly: true });
    });
  });

  describe('getAssetsByOriginalPath', () => {
    it('should return assets by original path', async () => {
      const path = '/asset';

      const asset1 = AssetFactory.create({ originalPath: '/asset/path1' });
      const asset2 = AssetFactory.create({ originalPath: '/asset/path2' });

      const mockAssets = [asset1, asset2];

      const mockAssetReponseDto = mockAssets.map((asset) => mapAsset(getForAsset(asset), { auth: authStub.admin }));

      mocks.view.getAssetsByOriginalPath.mockResolvedValue(mockAssets as any);

      const result = await sut.getAssetsByOriginalPath(authStub.admin, { path, externalOnly: true });
      expect(result).toEqual(mockAssetReponseDto);
      await expect(
        mocks.view.getAssetsByOriginalPath(authStub.admin.user.id, path, { externalOnly: true }),
      ).resolves.toEqual(mockAssets);
    });
  });

  describe('getFolderContent', () => {
    it('should return external library import paths on the root view', async () => {
      mocks.library.getByOwnerId.mockResolvedValue([
        { importPaths: ['/external/photos', '/external/videos'] },
        { importPaths: ['/external/photos', '/external/archive'] },
      ] as any);

      const result = await sut.getFolderContent(authStub.admin, { externalOnly: true });

      expect(result).toEqual({
        folders: ['/external/archive', '/external/photos', '/external/videos'],
        items: [],
      });
      expect(mocks.library.getByOwnerId).toHaveBeenCalledWith(authStub.admin.user.id);
      expect(mocks.view.getUniqueOriginalPaths).not.toHaveBeenCalled();
      expect(mocks.view.getAssetsByOriginalPath).not.toHaveBeenCalled();
    });

    it('should return an empty root view when import paths are cleared', async () => {
      mocks.library.getByOwnerId.mockResolvedValue([{ importPaths: [] }] as any);

      const result = await sut.getFolderContent(authStub.admin, { externalOnly: true });

      expect(result).toEqual({ folders: [], items: [] });
      expect(mocks.library.getByOwnerId).toHaveBeenCalledWith(authStub.admin.user.id);
    });

    it('should return immediate child folders and mapped assets', async () => {
      mocks.view.getUniqueOriginalPaths.mockResolvedValue(['/library/2023', '/library/2024/trips', '/other']);

      const asset = AssetFactory.create({ originalPath: '/library/photo.jpg' });
      mocks.view.getAssetsByOriginalPath.mockResolvedValue([asset] as any);

      const result = await sut.getFolderContent(authStub.admin, { path: '/library', externalOnly: true });

      expect(result.folders).toEqual(['/library/2023', '/library/2024']);
      expect(result.items).toEqual([mapAsset(getForAsset(asset), { auth: authStub.admin })]);
      expect(mocks.view.getUniqueOriginalPaths).toHaveBeenCalledWith(authStub.admin.user.id, { externalOnly: true });
      expect(mocks.view.getAssetsByOriginalPath).toHaveBeenCalledWith(authStub.admin.user.id, '/library', {
        externalOnly: true,
      });
    });
  });
});
