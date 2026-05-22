import { ApiProperty } from '@nestjs/swagger';
import { AssetResponseDto } from 'src/dtos/asset-response.dto';
import { Optional, ValidateBoolean, ValidateString } from 'src/validation';

export class ViewFolderQueryDto {
  @ValidateString({ optional: true, description: 'Folder path to browse' })
  path?: string;

  @ValidateBoolean({ optional: true, description: 'Only include externally scanned library assets' })
  externalOnly?: boolean;
}

export class ViewFolderContentResponseDto {
  @ApiProperty({ type: String, isArray: true, description: 'Immediate child folder paths' })
  folders!: string[];

  @ApiProperty({ type: AssetResponseDto, isArray: true, description: 'Assets in the current folder' })
  items!: AssetResponseDto[];
}
