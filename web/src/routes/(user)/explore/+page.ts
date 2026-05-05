import { authenticate } from '$lib/utils/auth';
import { getFormatter } from '$lib/utils/i18n';
import { getExploreData } from '@immich/sdk';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);
  const items = await getExploreData();
  const $t = await getFormatter();

  return {
    items,
    meta: {
      title: $t('explore'),
    },
  };
}) satisfies PageLoad;
