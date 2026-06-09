<script lang="ts">
  import { browseServerDirectories } from '$lib/services/library.service';
  import type { BrowseLibraryDirectoriesResponseDto } from '@immich/sdk';
  import { Button, Field, Input, ListButton, LoadingSpinner, Modal, ModalBody, ModalFooter, Text } from '@immich/ui';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';

  type Props = {
    onClose: (path?: string) => void;
  };

  const { onClose }: Props = $props();

  let result = $state<BrowseLibraryDirectoriesResponseDto>({ directories: [] });
  let isLoading = $state(false);
  let manualPath = $state('');
  let browseUnavailable = $state(false);

  const load = async (path?: string) => {
    isLoading = true;

    try {
      result = await browseServerDirectories(path);
      browseUnavailable = false;
      // Keep selection in sync with the browsed directory (do not stick on the first visited path).
      if (result.currentPath) {
        manualPath = result.currentPath;
      }
    } catch (error) {
      browseUnavailable = true;
      if (path) {
        manualPath = path;
      }
    } finally {
      isLoading = false;
    }
  };

  onMount(() => {
    void load();
  });
</script>

<Modal title={$t('add_path')} {onClose} size="small">
  <ModalBody>
    <div class="flex flex-col gap-3">
      {#if browseUnavailable}
        <div class="rounded-xl border border-[#D4D4D9] bg-[#F5F5F7] px-4 py-3 text-sm text-[#626266] dark:border-immich-dark-gray dark:bg-immich-dark-gray/40 dark:text-immich-dark-fg/80">
          Directory browsing is unavailable on the current server. Enter the import path manually.
        </div>

        <Field label={$t('path')}>
          <Input bind:value={manualPath} />
        </Field>
      {:else}
        <div class="rounded-xl border border-[#D4D4D9] bg-[#F5F5F7] px-4 py-3 text-sm text-[#626266] dark:border-immich-dark-gray dark:bg-immich-dark-gray/40 dark:text-immich-dark-fg/80">
          <Text size="small" fontWeight="medium">{$t('path')}</Text>
          <Text size="small" class="break-all">{result.currentPath ?? '/'}</Text>
        </div>

        {#if result.parentPath}
          <Button color="secondary" size="small" onclick={() => load(result.parentPath)}>Up</Button>
        {/if}

        <div class="immich-scrollbar flex max-h-96 flex-col gap-2 overflow-y-auto">
          {#if isLoading}
            <div class="flex min-h-32 items-center justify-center">
              <LoadingSpinner />
            </div>
          {:else if result.directories.length > 0}
            {#each result.directories as directory (directory.path)}
              <ListButton onclick={() => load(directory.path)}>
                <div class="min-w-0 grow text-start">
                  <Text fontWeight="medium">{directory.name}</Text>
                  <Text size="tiny" color="muted" class="break-all">{directory.path}</Text>
                </div>
              </ListButton>
            {/each}
          {:else}
            <div class="rounded-xl border border-dashed border-[#D4D4D9] px-4 py-6 text-center text-sm text-[#626266] dark:border-immich-dark-gray dark:text-immich-dark-fg/80">
              No folders found.
            </div>
          {/if}
        </div>
      {/if}
    </div>
  </ModalBody>

  <ModalFooter>
    <Button color="secondary" onclick={() => onClose()}>{$t('cancel')}</Button>
    <Button
      disabled={!manualPath && !result.currentPath}
      onclick={() => onClose((result.currentPath ?? manualPath) || undefined)}
    >
      {$t('select')}
    </Button>
  </ModalFooter>
</Modal>
