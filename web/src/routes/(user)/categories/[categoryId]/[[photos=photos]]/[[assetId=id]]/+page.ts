import { error } from '@sveltejs/kit';
import { authenticate } from '$lib/utils/auth';
import { parseCategoryType, getCategoryTitleKey } from '$lib/utils/categories';
import { getFormatter } from '$lib/utils/i18n';
import type { PageLoad } from './$types';

export const load = (async ({ params, url }) => {
  await authenticate(url);

  const categoryType = parseCategoryType(params.categoryId);
  if (!categoryType) {
    error(404, 'Category not found');
  }

  const $t = await getFormatter();

  return {
    categoryType,
    meta: {
      title: $t(getCategoryTitleKey(categoryType)),
    },
  };
}) satisfies PageLoad;
