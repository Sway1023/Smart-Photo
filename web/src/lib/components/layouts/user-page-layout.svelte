<script lang="ts" module>
  export const headerId = 'user-page-header';
</script>

<script lang="ts">
  import { useActions, type ActionArray } from '$lib/actions/use-actions';
  import NavigationBar from '$lib/components/shared-components/navigation-bar/navigation-bar.svelte';
  import UserSidebar from '$lib/components/shared-components/side-bar/user-sidebar.svelte';
  import type { HeaderButtonActionItem } from '$lib/types';
  import { openFileUploadDialog } from '$lib/utils/file-uploader';
  import { Button, ContextMenuButton, HStack, isMenuItemType, type MenuItemType } from '@immich/ui';
  import type { Snippet } from 'svelte';
  import { t } from 'svelte-i18n';

  interface Props {
    hideNavbar?: boolean;
    title?: string | undefined;
    description?: string | undefined;
    scrollbar?: boolean;
    use?: ActionArray;
    actions?: Array<HeaderButtonActionItem | MenuItemType>;
    sidebar?: Snippet;
    buttons?: Snippet;
    children?: Snippet;
  }

  let {
    hideNavbar = false,
    title = undefined,
    description = undefined,
    scrollbar = true,
    use = [],
    actions = [],
    sidebar,
    buttons,
    children,
  }: Props = $props();

  const enabledActions = $derived(
    actions
      .filter((action): action is HeaderButtonActionItem => !isMenuItemType(action))
      .filter((action) => action.$if?.() ?? true),
  );

  let scrollbarClass = $derived(scrollbar ? 'immich-scrollbar' : 'scrollbar-hidden');
  const contentAreaClass = $derived(
    hideNavbar
      ? 'top-0 h-full'
      : 'top-(--navbar-height) h-[calc(100%-var(--navbar-height))] max-md:top-(--navbar-height-md) max-md:h-[calc(100%-var(--navbar-height-md))]',
  );
</script>

<main class="relative h-dvh overflow-hidden bg-[#F5F5F7] p-1.5 text-dark dark:bg-immich-dark-bg xl:p-2">
  <div tabindex="-1" class="grid h-full grid-cols-[auto_minmax(0,1fr)] overflow-hidden gap-1.5 xl:gap-2">
    {#if sidebar}
      {@render sidebar()}
    {:else}
      <UserSidebar />
    {/if}

    <section class="relative min-w-0">
      {#if !hideNavbar}
        <div class="absolute inset-x-0 top-0 z-30 overflow-hidden rounded-[20px] bg-[#F5F5F7] dark:bg-immich-dark-bg">
          <NavigationBar onUploadClick={() => openFileUploadDialog()} />
        </div>
      {/if}

      <div class="absolute inset-x-0 bottom-0 {contentAreaClass}">
        <div class="flex h-full flex-col overflow-hidden rounded-[20px] bg-white shadow-[0_1px_2px_rgba(0,0,0,0.04)] dark:bg-immich-dark-bg">
          {#if title || description || buttons || enabledActions.length > 0}
            <div class="shrink-0 px-3 xl:px-4">
              <div class="flex min-h-16 items-center justify-between gap-4 border-b border-[#D4D4D9] py-3 dark:border-immich-dark-gray">
                <div class="flex min-w-0 items-center gap-2">
                  {#if title}
                    <div class="truncate text-xl font-medium leading-7 outline-none" tabindex="-1" id={headerId}>
                      {title}
                    </div>
                  {/if}
                  {#if description}
                    <p class="truncate text-sm text-gray-400 dark:text-gray-500">{description}</p>
                  {/if}
                </div>

                <div class="flex items-center gap-2">
                  {@render buttons?.()}

                  {#if enabledActions.length > 0}
                    <div class="hidden md:block">
                      <HStack gap={0}>
                        {#each enabledActions as action, i (i)}
                          <Button
                            variant="ghost"
                            size="small"
                            color={action.color ?? 'secondary'}
                            leadingIcon={action.icon}
                            onclick={() => action.onAction(action)}
                            title={action.data?.title}
                          >
                            {action.title}
                          </Button>
                        {/each}
                      </HStack>
                    </div>

                    <ContextMenuButton aria-label={$t('open')} items={actions} class="md:hidden" />
                  {/if}
                </div>
              </div>
            </div>
          {/if}

          <div
            class="{scrollbarClass} scrollbar-stable min-h-0 flex-1 overflow-y-auto px-3 pb-3 xl:px-4 xl:pb-4"
            use:useActions={use}
          >
            {@render children?.()}
          </div>
        </div>
      </div>
    </section>
  </div>
</main>
