<script lang="ts">
  import ActionMenuItem from '$lib/components/ActionMenuItem.svelte';
  import UserPageLayout from '$lib/components/layouts/user-page-layout.svelte';
  import ButtonContextMenu from '$lib/components/shared-components/context-menu/button-context-menu.svelte';
  import EmptyPlaceholder from '$lib/components/shared-components/empty-placeholder.svelte';
  import ArchiveAction from '$lib/components/timeline/actions/ArchiveAction.svelte';
  import ChangeDate from '$lib/components/timeline/actions/ChangeDateAction.svelte';
  import ChangeDescription from '$lib/components/timeline/actions/ChangeDescriptionAction.svelte';
  import ChangeLocation from '$lib/components/timeline/actions/ChangeLocationAction.svelte';
  import CreateSharedLink from '$lib/components/timeline/actions/CreateSharedLinkAction.svelte';
  import DeleteAssets from '$lib/components/timeline/actions/DeleteAssetsAction.svelte';
  import DownloadAction from '$lib/components/timeline/actions/DownloadAction.svelte';
  import FavoriteAction from '$lib/components/timeline/actions/FavoriteAction.svelte';
  import LinkLivePhotoAction from '$lib/components/timeline/actions/LinkLivePhotoAction.svelte';
  import SelectAllAssets from '$lib/components/timeline/actions/SelectAllAction.svelte';
  import TagAction from '$lib/components/timeline/actions/TagAction.svelte';
  import AssetSelectControlBar from '$lib/components/timeline/AssetSelectControlBar.svelte';
  import Timeline from '$lib/components/timeline/Timeline.svelte';
  import { AssetAction } from '$lib/constants';
  import { TimelineManager } from '$lib/managers/timeline-manager/timeline-manager.svelte';
  import { Route } from '$lib/route';
  import { getAssetBulkActions } from '$lib/services/asset.service';
  import { AssetInteraction } from '$lib/stores/asset-interaction.svelte';
  import { assetViewingStore } from '$lib/stores/asset-viewing.store';
  import { memoryStore } from '$lib/stores/memory.store.svelte';
  import { preferences, user } from '$lib/stores/user.store';
  import { getAssetMediaUrl, memoryLaneTitle } from '$lib/utils';
  import {
    type OnLink,
    type OnUnlink,
  } from '$lib/utils/actions';
  import { openFileUploadDialog } from '$lib/utils/file-uploader';
  import { getAltText } from '$lib/utils/thumbnail-util';
  import { toTimelineAsset } from '$lib/utils/timeline-util';
  import { AssetVisibility } from '@immich/sdk';
  import { ActionButton, CommandPaletteDefaultProvider, ImageCarousel } from '@immich/ui';
  import { mdiDotsVertical } from '@mdi/js';
  import { t } from 'svelte-i18n';

  let { isViewing: showAssetViewer } = assetViewingStore;
  let timelineManager = $state<TimelineManager>() as TimelineManager;
  const options = { visibility: AssetVisibility.Timeline, withStacked: true, withPartners: true };

  const assetInteraction = new AssetInteraction();

  let selectedAssets = $derived(assetInteraction.selectedAssets);
  let isLinkActionAvailable = $derived.by(() => {
    const isLivePhoto = selectedAssets.length === 1 && !!selectedAssets[0].livePhotoVideoId;
    const isLivePhotoCandidate =
      selectedAssets.length === 2 &&
      selectedAssets.some((asset) => asset.isImage) &&
      selectedAssets.some((asset) => asset.isVideo);

    return assetInteraction.isAllUserOwned && (isLivePhoto || isLivePhotoCandidate);
  });

  const handleEscape = () => {
    if ($showAssetViewer) {
      return;
    }
    if (assetInteraction.selectionActive) {
      assetInteraction.clearMultiselect();
      return;
    }
  };

  const handleLink: OnLink = ({ still, motion }) => {
    timelineManager.removeAssets([motion.id]);
    timelineManager.upsertAssets([still]);
  };

  const handleUnlink: OnUnlink = ({ still, motion }) => {
    timelineManager.upsertAssets([motion]);
    timelineManager.upsertAssets([still]);
  };

  const items = $derived(
    memoryStore.memories.map((memory) => ({
      id: memory.id,
      title: $memoryLaneTitle(memory),
      href: Route.memories({ id: memory.assets[0].id }),
      alt: $t('memory_lane_title', { values: { title: $getAltText(toTimelineAsset(memory.assets[0])) } }),
      src: getAssetMediaUrl({ id: memory.assets[0].id }),
    })),
  );
</script>

<UserPageLayout
  hideNavbar={assetInteraction.selectionActive}
  showTopBar={assetInteraction.selectionActive}
  scrollbar={false}
>
  {#snippet topbar()}
    <AssetSelectControlBar
      ownerId={$user.id}
      assets={assetInteraction.selectedAssets}
      clearSelect={() => assetInteraction.clearMultiselect()}
    >
      {@const Actions = getAssetBulkActions($t, assetInteraction.asControlContext())}
      <CommandPaletteDefaultProvider name={$t('assets')} actions={Object.values(Actions)} />

      <CreateSharedLink />
      <SelectAllAssets {timelineManager} {assetInteraction} />
      <ActionButton action={Actions.AddToAlbum} />

      {#if assetInteraction.isAllUserOwned}
        <FavoriteAction
          removeFavorite={assetInteraction.isAllFavorite}
          onFavorite={(ids, isFavorite) => timelineManager.update(ids, (asset) => (asset.isFavorite = isFavorite))}
        />

        <ButtonContextMenu icon={mdiDotsVertical} title={$t('menu')}>
          <DownloadAction menuItem />
          {#if isLinkActionAvailable}
            <LinkLivePhotoAction
              menuItem
              unlink={assetInteraction.selectedAssets.length === 1}
              onLink={handleLink}
              onUnlink={handleUnlink}
            />
          {/if}
          <ChangeDate menuItem />
          <ChangeDescription menuItem />
          <ChangeLocation menuItem />
          <ArchiveAction
            menuItem
            onArchive={(ids, visibility) => timelineManager.update(ids, (asset) => (asset.visibility = visibility))}
          />
          {#if $preferences.tags.enabled}
            <TagAction menuItem />
          {/if}
          <DeleteAssets
            menuItem
            onAssetDelete={(assetIds) => timelineManager.removeAssets(assetIds)}
            onUndoDelete={(assets) => timelineManager.upsertAssets(assets)}
          />
          <hr />
          <ActionMenuItem action={Actions.RegenerateThumbnailJob} />
          <ActionMenuItem action={Actions.RefreshMetadataJob} />
          <ActionMenuItem action={Actions.TranscodeVideoJob} />
        </ButtonContextMenu>
      {:else}
        <DownloadAction />
      {/if}
    </AssetSelectControlBar>
  {/snippet}

  <Timeline
    enableRouting={true}
    bind:timelineManager
    {options}
    {assetInteraction}
    removeAction={AssetAction.ARCHIVE}
    onEscape={handleEscape}
    withStacked
  >
    {#if $preferences.memories.enabled}
      <ImageCarousel {items} />
    {/if}
    {#snippet empty()}
      <EmptyPlaceholder text={$t('no_assets_message')} onClick={() => openFileUploadDialog()} class="mt-10 mx-auto" />
    {/snippet}
  </Timeline>
</UserPageLayout>
