<script lang="ts">
  import { afterNavigate, goto, invalidateAll } from '$app/navigation';
  import ActionMenuItem from '$lib/components/ActionMenuItem.svelte';
  import emptyGeneralUrl from '$lib/assets/empty-general.svg';
  import folderIconUrl from '$lib/assets/folder-icon.svg';
  import UserPageLayout from '$lib/components/layouts/user-page-layout.svelte';
  import EmptyPlaceholder from '$lib/components/shared-components/empty-placeholder.svelte';
  import ButtonContextMenu from '$lib/components/shared-components/context-menu/button-context-menu.svelte';
  import GalleryViewer from '$lib/components/shared-components/gallery-viewer/gallery-viewer.svelte';
  import ArchiveAction from '$lib/components/timeline/actions/ArchiveAction.svelte';
  import ChangeDate from '$lib/components/timeline/actions/ChangeDateAction.svelte';
  import ChangeDescription from '$lib/components/timeline/actions/ChangeDescriptionAction.svelte';
  import ChangeLocation from '$lib/components/timeline/actions/ChangeLocationAction.svelte';
  import CreateSharedLink from '$lib/components/timeline/actions/CreateSharedLinkAction.svelte';
  import DeleteAssets from '$lib/components/timeline/actions/DeleteAssetsAction.svelte';
  import DownloadAction from '$lib/components/timeline/actions/DownloadAction.svelte';
  import FavoriteAction from '$lib/components/timeline/actions/FavoriteAction.svelte';
  import TagAction from '$lib/components/timeline/actions/TagAction.svelte';
  import AssetSelectControlBar from '$lib/components/timeline/AssetSelectControlBar.svelte';
  import type { Viewport } from '$lib/managers/timeline-manager/types';
  import { Route } from '$lib/route';
  import { getAssetBulkActions } from '$lib/services/asset.service';
  import { AssetInteraction } from '$lib/stores/asset-interaction.svelte';
  import { preferences } from '$lib/stores/user.store';
  import { cancelMultiselect } from '$lib/utils/asset-utils';
  import { toTimelineAsset } from '$lib/utils/timeline-util';
  import type { AssetResponseDto } from '@immich/sdk';
  import { ActionButton, CommandPaletteDefaultProvider, IconButton } from '@immich/ui';
  import { mdiDotsVertical, mdiSelectAll } from '@mdi/js';
  import { t } from 'svelte-i18n';
  import { getFolderLabel, resolveBreadcrumbTrail, type FolderBreadcrumb } from './folder-content';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();

  const viewport: Viewport = $state({ width: 0, height: 0 });
  const assetInteraction = new AssetInteraction();
  let breadcrumbTrail = $state<FolderBreadcrumb[]>([]);
  const isEmptyFolderView = $derived(data.folders.length === 0 && data.items.length === 0);

  afterNavigate(() => {
    cancelMultiselect(assetInteraction);
    breadcrumbTrail = resolveBreadcrumbTrail(breadcrumbTrail, data.currentPath);
  });

  function navigateToView(path?: string) {
    return goto(Route.folders(path ? { path } : undefined), { keepFocus: true, noScroll: true });
  }

  async function triggerAssetUpdate() {
    cancelMultiselect(assetInteraction);
    await invalidateAll();
  }

  function handleSelectAllAssets() {
    assetInteraction.selectAssets(data.items.map((asset: AssetResponseDto) => toTimelineAsset(asset)));
  }
</script>

<UserPageLayout
  title={data.meta.title}
  hideNavbar={assetInteraction.selectionActive}
  showTopBar={assetInteraction.selectionActive}
>
  {#snippet topbar()}
    <AssetSelectControlBar
      assets={assetInteraction.selectedAssets}
      clearSelect={() => cancelMultiselect(assetInteraction)}
    >
      {@const Actions = getAssetBulkActions($t, assetInteraction.asControlContext())}
      <CommandPaletteDefaultProvider name={$t('assets')} actions={Object.values(Actions)} />
      <CreateSharedLink />
      <IconButton
        shape="round"
        color="secondary"
        variant="ghost"
        aria-label={$t('select_all')}
        icon={mdiSelectAll}
        onclick={handleSelectAllAssets}
      />
      <ActionButton action={Actions.AddToAlbum} />
      <FavoriteAction
        removeFavorite={assetInteraction.isAllFavorite}
        onFavorite={(ids, isFavorite) => {
          for (const id of ids) {
            const asset = data.items.find((item: AssetResponseDto) => item.id === id);
            if (asset) {
              asset.isFavorite = isFavorite;
            }
          }
        }}
      />

      <ButtonContextMenu icon={mdiDotsVertical} title={$t('menu')}>
        <DownloadAction menuItem />
        <ChangeDate menuItem />
        <ChangeDescription menuItem />
        <ChangeLocation menuItem />
        <ArchiveAction menuItem unarchive={assetInteraction.isAllArchived} onArchive={triggerAssetUpdate} />
        {#if $preferences.tags.enabled && assetInteraction.isAllUserOwned}
          <TagAction menuItem />
        {/if}
        <DeleteAssets menuItem onAssetDelete={triggerAssetUpdate} onUndoDelete={triggerAssetUpdate} />
        <hr />

        <ActionMenuItem action={Actions.RegenerateThumbnailJob} />
        <ActionMenuItem action={Actions.RefreshMetadataJob} />
        <ActionMenuItem action={Actions.TranscodeVideoJob} />
      </ButtonContextMenu>
    </AssetSelectControlBar>
  {/snippet}

  <section class="flex h-full w-full flex-col overflow-auto immich-scrollbar">
    <div class="flex flex-col gap-4">
      <nav
        aria-label={$t('folders')}
        class="flex min-w-0 items-center gap-1 overflow-hidden whitespace-nowrap text-sm text-slate-500 dark:text-slate-400"
      >
        <button type="button" class="truncate px-1 py-0.5 hover:text-slate-700 dark:hover:text-slate-200" onclick={() => navigateToView()}>
          {$t('folders')}
        </button>

        {#each breadcrumbTrail as crumb, index (crumb.path)}
          <span aria-hidden="true" class="shrink-0 px-1 text-slate-300 dark:text-slate-600">/</span>

          {#if index === breadcrumbTrail.length - 1}
            <span class="truncate px-1 py-0.5 font-medium text-slate-900 dark:text-slate-100">{crumb.label}</span>
          {:else}
            <button
              type="button"
              class="truncate px-1 py-0.5 hover:text-slate-700 dark:hover:text-slate-200"
              onclick={() => navigateToView(crumb.path)}
            >
              {crumb.label}
            </button>
          {/if}
        {/each}
      </nav>

      {#if data.folders.length > 0}
        <div class="flex flex-wrap gap-4">
          {#each data.folders as folder}
            <button
              type="button"
              title={folder}
              onclick={() => navigateToView(folder)}
              class="flex h-[124px] w-[148px] shrink-0 flex-col items-center rounded-[8px] bg-[#F5F5F7] px-[12px] pb-[8px] pt-[16px] text-left transition-opacity hover:opacity-90 dark:bg-immich-dark-gray/40"
            >
              <div class="flex h-[64px] w-[64px] shrink-0 items-center justify-center">
                <img src={folderIconUrl} alt="" class="h-[64px] w-[64px] shrink-0 object-contain" draggable="false" />
              </div>
              <span class="mt-auto h-[36px] w-[124px] overflow-hidden text-center text-[14px] leading-[18px] line-clamp-2 [word-break:break-all]">
                {getFolderLabel(folder)}
              </span>
            </button>
          {/each}
        </div>
      {/if}
    </div>

    {#if data.items.length > 0}
      <div bind:clientHeight={viewport.height} bind:clientWidth={viewport.width} class="mt-4">
        <GalleryViewer
          assets={data.items}
          {assetInteraction}
          {viewport}
          showAssetName={true}
          pageHeaderOffset={54}
          onReload={triggerAssetUpdate}
        />
      </div>
    {/if}

    {#if isEmptyFolderView}
      <EmptyPlaceholder
        fullWidth
        src={emptyGeneralUrl}
        imgWidth={200}
        text={$t('empty_folder')}
        class="mt-10 bg-transparent dark:bg-transparent"
      />
    {/if}
  </section>
</UserPageLayout>
