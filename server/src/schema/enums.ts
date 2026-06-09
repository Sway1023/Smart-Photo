import { registerEnum } from '@immich/sql-tools';
import { AssetStatus, AssetVisibility } from 'src/enum';

export const assets_status_enum = registerEnum({
  name: 'assets_status_enum',
  values: Object.values(AssetStatus),
});

export const asset_visibility_enum = registerEnum({
  name: 'asset_visibility_enum',
  values: Object.values(AssetVisibility),
});
