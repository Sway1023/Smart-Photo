<script lang="ts">
  import { page } from '$app/state';
  import BottomInfo from '$lib/components/shared-components/side-bar/bottom-info.svelte';
  import RecentAlbums from '$lib/components/shared-components/side-bar/recent-albums.svelte';
  import Sidebar from '$lib/components/sidebar/sidebar.svelte';
  import { featureFlagsManager } from '$lib/managers/feature-flags-manager.svelte';
  import { Route } from '$lib/route';
  import { isSidebarCollapsed, recentAlbumsDropdown } from '$lib/stores/preferences.store';
  import { preferences } from '$lib/stores/user.store';
  import { Icon } from '@immich/ui';
  import {
    mdiAccountMultiple,
    mdiAccountMultipleOutline,
    mdiArchiveArrowDown,
    mdiArchiveArrowDownOutline,
    mdiChevronDoubleLeft,
    mdiChevronDown,
    mdiFolderOutline,
    mdiHeart,
    mdiHeartOutline,
    mdiImageAlbum,
    mdiImageMultiple,
    mdiImageMultipleOutline,
    mdiLink,
    mdiLock,
    mdiLockOutline,
    mdiMagnify,
    mdiMap,
    mdiMapOutline,
    mdiTagMultipleOutline,
    mdiToolbox,
    mdiToolboxOutline,
    mdiTrashCan,
    mdiTrashCanOutline,
    mdiViewGrid,
    mdiViewGridOutline,
  } from '@mdi/js';
  import { t } from 'svelte-i18n';

  type SidebarItem = {
    key: string;
    title: string;
    href: string;
    icon: string;
    activeIcon?: string;
    active: boolean;
  };

  const isActive = (href: string) => {
    const pathname = page.url.pathname;
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const toggleSidebar = () => {
    isSidebarCollapsed.update((collapsed) => !collapsed);
  };

  const toggleRecentAlbums = () => {
    recentAlbumsDropdown.update((expanded) => !expanded);
  };

  const mainItems = $derived.by(() => {
    const items: SidebarItem[] = [
      {
        key: 'photos',
        title: $t('photos'),
        href: Route.photos(),
        icon: mdiImageMultipleOutline,
        activeIcon: mdiImageMultiple,
        active: isActive(Route.photos()),
      },
    ];

    if (featureFlagsManager.value.search) {
      items.push({
        key: 'explore',
        title: $t('explore'),
        href: Route.explore(),
        icon: mdiMagnify,
        active: isActive(Route.explore()),
      });
    }

    if (featureFlagsManager.value.map) {
      items.push({
        key: 'map',
        title: $t('map'),
        href: Route.map(),
        icon: mdiMapOutline,
        activeIcon: mdiMap,
        active: isActive(Route.map()),
      });
    }

    if ($preferences.sharedLinks.enabled && $preferences.sharedLinks.sidebarWeb) {
      items.push({
        key: 'shared-links',
        title: $t('shared_links'),
        href: Route.sharedLinks(),
        icon: mdiLink,
        active: isActive(Route.sharedLinks()),
      });
    }

    items.push({
      key: 'sharing',
      title: $t('sharing'),
      href: Route.sharing(),
      icon: mdiAccountMultipleOutline,
      activeIcon: mdiAccountMultiple,
      active: isActive(Route.sharing()),
    });

    return items;
  });

  const libraryItems = $derived.by(() => {
    const items: SidebarItem[] = [
      {
        key: 'favorites',
        title: $t('favorites'),
        href: Route.favorites(),
        icon: mdiHeartOutline,
        activeIcon: mdiHeart,
        active: isActive(Route.favorites()),
      },
      {
        key: 'albums',
        title: $t('albums'),
        href: Route.albums(),
        icon: mdiImageAlbum,
        active: isActive(Route.albums()),
      },
    ];

    items.push({
      key: 'categories',
      title: $t('search_page_categories'),
      href: Route.categories(),
      icon: mdiViewGridOutline,
      activeIcon: mdiViewGrid,
      active: isActive(Route.categories()),
    });

    if ($preferences.tags.enabled && $preferences.tags.sidebarWeb) {
      items.push({
        key: 'tags',
        title: $t('tags'),
        href: Route.tags(),
        icon: mdiTagMultipleOutline,
        active: isActive(Route.tags()),
      });
    }

    if ($preferences.folders.enabled && $preferences.folders.sidebarWeb) {
      items.push({
        key: 'folders',
        title: $t('folders'),
        href: Route.folders(),
        icon: mdiFolderOutline,
        active: isActive(Route.folders()),
      });
    }

    items.push(
      {
        key: 'utilities',
        title: $t('utilities'),
        href: Route.utilities(),
        icon: mdiToolboxOutline,
        activeIcon: mdiToolbox,
        active: isActive(Route.utilities()),
      },
      {
        key: 'archive',
        title: $t('archive'),
        href: Route.archive(),
        icon: mdiArchiveArrowDownOutline,
        activeIcon: mdiArchiveArrowDown,
        active: isActive(Route.archive()),
      },
      {
        key: 'locked',
        title: $t('locked_folder'),
        href: Route.locked(),
        icon: mdiLockOutline,
        activeIcon: mdiLock,
        active: isActive(Route.locked()),
      },
    );

    if (featureFlagsManager.value.trash) {
      items.push({
        key: 'trash',
        title: $t('trash'),
        href: Route.trash(),
        icon: mdiTrashCanOutline,
        activeIcon: mdiTrashCan,
        active: isActive(Route.trash()),
      });
    }

    return items;
  });
</script>

{#snippet sectionLabel(label: string)}
  {#if !$isSidebarCollapsed}
    <div class="px-3 pt-5 pb-2 text-[11px] font-semibold uppercase tracking-[0.14em] text-[#8B8B91] dark:text-immich-dark-fg/60">
      {label}
    </div>
  {:else}
    <div class="px-4 py-3">
      <div class="h-px rounded-full bg-[#D4D4D9] dark:bg-immich-dark-gray"></div>
    </div>
  {/if}
{/snippet}

{#snippet itemRow(item: SidebarItem)}
  <a
    href={item.href}
    class="group flex h-12 items-center rounded-xl text-[#626266] transition-colors hover:bg-white/80 hover:text-[#1D1D1F] dark:text-immich-dark-fg/80 dark:hover:bg-immich-dark-gray/70 dark:hover:text-immich-dark-fg {$isSidebarCollapsed
      ? 'justify-center px-0'
      : 'gap-3 px-4'} {item.active
      ? 'bg-white text-[#1D1D1F] shadow-[0_1px_2px_rgba(0,0,0,0.04)] dark:bg-immich-dark-gray dark:text-immich-dark-fg'
      : ''}"
    aria-current={item.active ? 'page' : undefined}
    title={$isSidebarCollapsed ? item.title : undefined}
  >
    <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg">
      <Icon icon={item.active && item.activeIcon ? item.activeIcon : item.icon} size="22" />
    </span>

    {#if !$isSidebarCollapsed}
      <span class="min-w-0 truncate text-sm font-medium">{item.title}</span>
    {/if}
  </a>
{/snippet}

<Sidebar ariaLabel={$t('primary')} collapsible collapsed={$isSidebarCollapsed}>
  <div class="flex min-h-full flex-col gap-2 rounded-[20px] bg-[#ECECF1] p-3 dark:bg-immich-dark-gray/40">
    <div class="flex flex-col gap-1">
      {#each mainItems as item (item.key)}
        {@render itemRow(item)}
      {/each}
    </div>

    {@render sectionLabel($t('library'))}

    <div class="flex flex-col gap-1">
      {#each libraryItems as item (item.key)}
        {#if item.key === 'albums'}
          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1">
              <a
                href={item.href}
                class="group flex h-12 min-w-0 flex-1 items-center rounded-xl text-[#626266] transition-colors hover:bg-white/80 hover:text-[#1D1D1F] dark:text-immich-dark-fg/80 dark:hover:bg-immich-dark-gray/70 dark:hover:text-immich-dark-fg {$isSidebarCollapsed
                  ? 'justify-center px-0'
                  : 'gap-3 px-4'} {item.active
                  ? 'bg-white text-[#1D1D1F] shadow-[0_1px_2px_rgba(0,0,0,0.04)] dark:bg-immich-dark-gray dark:text-immich-dark-fg'
                  : ''}"
                aria-current={item.active ? 'page' : undefined}
                title={$isSidebarCollapsed ? item.title : undefined}
              >
                <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg">
                  <Icon icon={item.icon} size="22" />
                </span>

                {#if !$isSidebarCollapsed}
                  <span class="min-w-0 truncate text-sm font-medium">{item.title}</span>
                {/if}
              </a>

              {#if !$isSidebarCollapsed}
                <button
                  type="button"
                  class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl text-[#626266] transition-colors hover:bg-white/80 hover:text-[#1D1D1F] dark:text-immich-dark-fg/80 dark:hover:bg-immich-dark-gray/70 dark:hover:text-immich-dark-fg"
                  onclick={toggleRecentAlbums}
                  aria-expanded={$recentAlbumsDropdown}
                  aria-label={$recentAlbumsDropdown ? $t('close') : $t('open')}
                  title={$recentAlbumsDropdown ? $t('close') : $t('open')}
                >
                  <span class={$recentAlbumsDropdown ? 'rotate-180 transition-transform duration-200' : 'transition-transform duration-200'}>
                    <Icon icon={mdiChevronDown} size="20" />
                  </span>
                </button>
              {/if}
            </div>

            {#if !$isSidebarCollapsed && $recentAlbumsDropdown}
              <div class="space-y-1 rounded-xl bg-white/70 px-2 py-1 dark:bg-immich-dark-gray/60">
                <RecentAlbums />
              </div>
            {/if}
          </div>
        {:else}
          {@render itemRow(item)}
        {/if}
      {/each}
    </div>

    <div class="mt-auto flex flex-col gap-3 pt-4">
      {#if !$isSidebarCollapsed}
        <BottomInfo />
      {/if}

      <button
        type="button"
        class="flex h-12 items-center rounded-xl text-[#626266] transition-colors hover:bg-white/80 hover:text-[#1D1D1F] dark:text-immich-dark-fg/80 dark:hover:bg-immich-dark-gray/70 dark:hover:text-immich-dark-fg {$isSidebarCollapsed
          ? 'justify-center px-0'
          : 'gap-3 px-4'}"
        onclick={toggleSidebar}
        title={$isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        aria-label={$isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
      >
        <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg">
          <span class={$isSidebarCollapsed ? 'rotate-180 transition-transform duration-200' : 'transition-transform duration-200'}>
            <Icon icon={mdiChevronDoubleLeft} size="22" />
          </span>
        </span>

        {#if !$isSidebarCollapsed}
          <span class="text-sm font-medium">Collapse</span>
        {/if}
      </button>
    </div>
  </div>
</Sidebar>
