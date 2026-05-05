import { authenticate } from '$lib/utils/auth';
import { getCategoryTitleKey } from '$lib/utils/categories';
import { getFormatter } from '$lib/utils/i18n';
import { getCategories } from '@immich/sdk';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);
  const [$t, categories] = await Promise.all([getFormatter(), getCategories()]);

  return {
    categories,
    meta: {
      title: $t('search_page_categories'),
    },
    categoryTitles: Object.fromEntries(categories.map((item) => [item.type, $t(getCategoryTitleKey(item.type))])),
  };
}) satisfies PageLoad;
