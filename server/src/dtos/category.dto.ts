import { ApiProperty } from '@nestjs/swagger';
import { CategoryType } from 'src/enum';
import { ValidateEnum } from 'src/validation';

export class CategoryCoverDto {
  @ApiProperty({
    type: 'string',
    description: 'Asset ID used as the category cover',
  })
  id!: string;

  @ApiProperty({
    type: 'string',
    nullable: true,
    description: 'Base64 encoded thumbhash for the cover asset',
  })
  thumbhash!: string | null;
}

export class CategoryItemDto {
  @ValidateEnum({
    enum: CategoryType,
    name: 'CategoryType',
    description: 'Derived category type for the asset collection',
  })
  type!: CategoryType;

  @ApiProperty({
    type: 'integer',
    description: 'Number of assets in the category',
  })
  count!: number;

  @ApiProperty({
    type: CategoryCoverDto,
    nullable: true,
    description: 'Latest visible asset used as the category cover',
  })
  cover!: CategoryCoverDto | null;
}
