<script lang="ts">
  import type { HeaderButtonActionItem } from '$lib/types';
  import {
    Breadcrumbs,
    Button,
    Container,
    ContextMenuButton,
    HStack,
    IconButton,
    MenuItemType,
    Scrollable,
    isMenuItemType,
    type BreadcrumbItem,
  } from '@immich/ui';
  import { mdiArrowLeft, mdiSlashForward } from '@mdi/js';
  import type { Snippet } from 'svelte';
  import { t } from 'svelte-i18n';

  type Props = {
    breadcrumbs?: BreadcrumbItem[];
    backHref?: string;
    actions?: Array<HeaderButtonActionItem | MenuItemType>;
    children?: Snippet;
  };

  let { breadcrumbs = [], backHref, actions = [], children }: Props = $props();

  const enabledActions = $derived(
    actions
      .filter((action): action is HeaderButtonActionItem => !isMenuItemType(action))
      .filter((action) => action.$if?.() ?? true),
  );
</script>

<div class="h-full flex flex-col">
  <div class="flex h-16 w-full justify-between items-center border-b py-2 px-4 md:px-2">
    <div class="flex min-w-0 items-center gap-1">
      {#if backHref}
        <IconButton
          shape="round"
          color="secondary"
          variant="ghost"
          icon={mdiArrowLeft}
          aria-label={$t('go_back')}
          href={backHref}
        />
      {/if}
      <Breadcrumbs items={breadcrumbs} separator={mdiSlashForward} />
    </div>

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
  <Scrollable class="grow">
    <Container class="p-2 pb-16" {children} />
  </Scrollable>
</div>
