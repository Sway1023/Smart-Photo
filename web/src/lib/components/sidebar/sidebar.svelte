<script lang="ts">
  import { clickOutside } from '$lib/actions/click-outside';
  import { focusTrap } from '$lib/actions/focus-trap';
  import { menuButtonId } from '$lib/components/shared-components/navigation-bar/navigation-bar.svelte';
  import { mediaQueryManager } from '$lib/stores/media-query-manager.svelte';
  import { sidebarStore } from '$lib/stores/sidebar.svelte';
  import { onMount, type Snippet } from 'svelte';

  interface Props {
    ariaLabel?: string;
    collapsible?: boolean;
    collapsed?: boolean;
    children?: Snippet;
  }

  let { ariaLabel, collapsible = false, collapsed = false, children }: Props = $props();

  const isHidden = $derived(!sidebarStore.isOpen && !mediaQueryManager.isFullSidebar);
  const isExpanded = $derived(sidebarStore.isOpen && !mediaQueryManager.isFullSidebar);
  const desktopWidthClass = $derived.by(() => {
    if (!collapsible) {
      return 'sidebar:w-64';
    }

    return collapsed ? 'sidebar:w-[5.5rem]' : 'sidebar:w-64';
  });

  onMount(() => {
    closeSidebar();
  });

  const closeSidebar = () => {
    if (!isExpanded) {
      return;
    }
    sidebarStore.reset();
    if (isHidden) {
      document.querySelector<HTMLButtonElement>(`#${menuButtonId}`)?.focus();
    }
  };
</script>

<nav
  id="sidebar"
  aria-label={ariaLabel}
  tabindex="-1"
  class="immich-scrollbar relative z-10 w-0 overflow-y-auto overflow-x-hidden bg-[#F5F5F7] pt-3 transition-[width] duration-200 dark:bg-immich-dark-bg {desktopWidthClass}"
  class:shadow-2xl={isExpanded}
  class:dark:border-e-immich-dark-gray={isExpanded}
  class:border-r={isExpanded}
  class:w-[min(100vw,16rem)]={sidebarStore.isOpen}
  data-testid="sidebar-parent"
  inert={isHidden}
  use:clickOutside={{ onOutclick: closeSidebar, onEscape: closeSidebar }}
  use:focusTrap={{ active: isExpanded }}
>
  <div
    class="flex h-max min-h-full flex-col gap-1 pe-3"
    class:pe-2={collapsible && collapsed}
    class:pe-3={!collapsible || !collapsed}
  >
    {@render children?.()}
  </div>
</nav>
