import { Injectable } from '@nestjs/common';
import { AssetResponseDto, mapAsset } from 'src/dtos/asset-response.dto';
import { AuthDto } from 'src/dtos/auth.dto';
import { ViewFolderQueryDto } from 'src/dtos/view.dto';
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
}
