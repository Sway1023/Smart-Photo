import { QueryParameter } from '$lib/constants';
import { authenticate } from '$lib/utils/auth';
import { getFormatter } from '$lib/utils/i18n';
import { getFolderContent } from '@immich/sdk';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);

  const path = url.searchParams.get(QueryParameter.PATH);
  const [$t, content] = await Promise.all([getFormatter(), getFolderContent({ path: path ?? undefined, externalOnly: true })]);

  return {
    currentPath: path ?? '',
    folders: content.folders,
    items: content.items,
    meta: {
      title: $t('folders'),
    },
  };
}) satisfies PageLoad;
