import { Injectable } from '@nestjs/common';
import { AssetResponseDto, mapAsset } from 'src/dtos/asset-response.dto';
import { AuthDto } from 'src/dtos/auth.dto';
import { ViewFolderContentResponseDto, ViewFolderQueryDto } from 'src/dtos/view.dto';
import { BaseService } from 'src/services/base.service';

@Injectable()
export class ViewService extends BaseService {
  getUniqueOriginalPaths(auth: AuthDto, dto: ViewFolderQueryDto): Promise<string[]> {
    return this.viewRepository.getUniqueOriginalPaths(auth.user.id, { externalOnly: dto.externalOnly });
  }

  async getAssetsByOriginalPath(auth: AuthDto, dto: ViewFolderQueryDto): Promise<AssetResponseDto[]> {
    const assets = await this.viewRepository.getAssetsByOriginalPath(auth.user.id, dto.path ?? '', {
      externalOnly: dto.externalOnly,
    });
    return assets.map((asset) => mapAsset(asset, { auth }));
  }

  async getFolderContent(auth: AuthDto, dto: ViewFolderQueryDto): Promise<ViewFolderContentResponseDto> {
    if (dto.externalOnly && !dto.path) {
      return {
        folders: await this.getExternalLibraryImportPaths(auth.user.id),
        items: [],
      };
    }

    const [paths, assets] = await Promise.all([
      this.viewRepository.getUniqueOriginalPaths(auth.user.id, { externalOnly: dto.externalOnly }),
      this.viewRepository.getAssetsByOriginalPath(auth.user.id, dto.path ?? '', { externalOnly: dto.externalOnly }),
    ]);

    return {
      folders: getImmediateChildFolders(paths, dto.path ?? ''),
      items: assets.map((asset) => mapAsset(asset, { auth })),
    };
  }

  private async getExternalLibraryImportPaths(userId: string) {
    const libraries = await this.libraryRepository.getByOwnerId(userId);
    return [...new Set(libraries.flatMap((library) => library.importPaths))].sort((left, right) => left.localeCompare(right));
  }
}

const normalizeFolderPath = (input: string) => (input.length > 1 && input.endsWith('/') ? input.slice(0, -1) : input);

const getImmediateChildFolders = (paths: string[], currentPath: string) => {
  const normalizedCurrentPath = normalizeFolderPath(currentPath);
  const children = new Set<string>();

  for (const item of paths) {
    const normalizedPath = normalizeFolderPath(item);
    const remainder = normalizedCurrentPath
      ? normalizedPath.startsWith(`${normalizedCurrentPath}/`)
        ? normalizedPath.slice(normalizedCurrentPath.length + 1)
        : ''
      : normalizedPath.startsWith('/')
        ? normalizedPath.slice(1)
        : normalizedPath;

    if (!remainder) {
      continue;
    }

    const [firstSegment] = remainder.split('/');
    if (!firstSegment) {
      continue;
    }

    children.add(
      normalizedCurrentPath
        ? `${normalizedCurrentPath}/${firstSegment}`
        : `${normalizedPath.startsWith('/') ? '/' : ''}${firstSegment}`,
    );
  }

  return [...children].sort((left, right) => left.localeCompare(right));
};
