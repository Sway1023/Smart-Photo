import { CategoryType } from '@immich/sdk';

export const getCategoryTitleKey = (categoryType: CategoryType) => {
  switch (categoryType) {
    case CategoryType.PICTURES:
      return 'category_pictures';
    case CategoryType.ANIMATION:
      return 'category_animation';
    case CategoryType.LIVE_PHOTO:
      return 'category_live_photo';
    case CategoryType.VIDEO:
      return 'video';
  }
};

export const parseCategoryType = (value: string): CategoryType | null => {
  if (Object.values(CategoryType).includes(value as CategoryType)) {
    return value as CategoryType;
  }

  return null;
};
