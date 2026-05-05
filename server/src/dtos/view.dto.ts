import { Optional, ValidateBoolean, ValidateString } from 'src/validation';

export class ViewFolderQueryDto {
  @ValidateString({ optional: true, description: 'Folder path to browse' })
  path?: string;

  @ValidateBoolean({ optional: true, description: 'Only include externally scanned library assets' })
  externalOnly?: boolean;
}
