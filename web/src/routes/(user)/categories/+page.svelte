<script lang="ts">
  import UserPageLayout from '$lib/components/layouts/user-page-layout.svelte';
  import EmptyPlaceholder from '$lib/components/shared-components/empty-placeholder.svelte';
  import { Route } from '$lib/route';
  import { getAssetMediaUrl } from '$lib/utils';
  import { AssetMediaSize } from '@immich/sdk';
  import { t } from 'svelte-i18n';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();
</script>

<UserPageLayout title={data.meta.title}>
  {#if data.categories.length > 0}
    <div class="grid grid-cols-[repeat(auto-fill,minmax(220px,1fr))] gap-4">
      {#each data.categories as category (category.type)}
        <a
          href={Route.viewCategory({ id: category.type })}
          class="group overflow-hidden rounded-2xl border border-[#D4D4D9] bg-white shadow-[0_8px_24px_rgba(15,23,42,0.06)] transition-transform duration-200 hover:-translate-y-0.5 dark:border-immich-dark-gray dark:bg-immich-dark-gray/60"
        >
          <div class="relative aspect-square overflow-hidden bg-[#ECECF1] dark:bg-immich-dark-bg/80">
            {#if category.cover}
              <img
                src={getAssetMediaUrl({ id: category.cover.id, size: AssetMediaSize.Thumbnail, cacheKey: category.cover.thumbhash })}
                alt={data.categoryTitles[category.type]}
                class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                draggable="false"
              />
              <div class="absolute inset-0 bg-gradient-to-t from-black/55 via-black/10 to-transparent"></div>
            {:else}
              <div class="absolute inset-0 bg-[#ECECF1] dark:bg-immich-dark-bg/80"></div>
            {/if}

            <div class="absolute inset-x-0 bottom-0 p-4 text-white">
              <p class="text-lg font-semibold">{data.categoryTitles[category.type]}</p>
              <p class="text-sm text-white/85">{category.count}</p>
            </div>
          </div>
        </a>
      {/each}
    </div>
  {:else}
    <EmptyPlaceholder text={$t('no_assets_message')} class="mt-10 mx-auto" />
  {/if}
</UserPageLayout>
