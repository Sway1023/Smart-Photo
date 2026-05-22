<script lang="ts">
  import { goto } from '$app/navigation';
  import AdminPageLayout from '$lib/components/layouts/AdminPageLayout.svelte';
  import OnEvents from '$lib/components/OnEvents.svelte';
  import { Route } from '$lib/route';
  import {
    PRIMARY_EXTERNAL_LIBRARY_NAME,
    getLibrariesActions,
    getManagedLibraryFolders,
    getPrimaryLibrary,
    handleAddFolderToPrimaryLibrary,
    handleDeleteLibraryFolder,
    pickServerLibraryDirectory,
    type ManagedLibraryFolder,
  } from '$lib/services/library.service';
  import { user } from '$lib/stores/user.store';
  import { Button, CommandPaletteDefaultProvider, Container, Text, toastManager } from '@immich/ui';
  import { mdiPlusBoxOutline } from '@mdi/js';
  import type { Snippet } from 'svelte';
  import { t } from 'svelte-i18n';
  import type { LayoutData } from './$types';

  type Props = {
    children?: Snippet;
    data: LayoutData;
  };

  let { children, data }: Props = $props();

  let libraries = $state(data.libraries);

  const { ScanAll } = $derived(getLibrariesActions($t));
  const managedFolders = $derived(getManagedLibraryFolders(libraries));

  const ownerId = () => getPrimaryLibrary(libraries)?.ownerId ?? $user.id;

  const onLibraryCreate = (library: LayoutData['libraries'][number]) => {
    libraries = [...libraries, library];
  };

  const onLibraryUpdate = (library: LayoutData['libraries'][number]) => {
    const index = libraries.findIndex(({ id }) => id === library.id);
    if (index === -1) {
      libraries = [...libraries, library];
      return;
    }

    libraries[index] = library;
  };

  const onLibraryDelete = ({ id }: { id: string }) => {
    libraries = libraries.filter((library) => library.id !== id);
  };

  const handleAddPath = async () => {
    const folder = await pickServerLibraryDirectory();
    if (!folder) {
      return;
    }

    if (managedFolders.some((item) => item.path === folder)) {
      toastManager.danger($t('errors.library_folder_already_exists'));
      return;
    }

    await handleAddFolderToPrimaryLibrary(libraries, ownerId(), folder);
  };

  const handleRemovePath = async ({ library, path }: ManagedLibraryFolder) => {
    await handleDeleteLibraryFolder(library, path);
  };

  const AddPath = {
    title: $t('add_path'),
    type: $t('command'),
    icon: mdiPlusBoxOutline,
    onAction: () => handleAddPath(),
    shortcuts: { shift: true, key: 'n' },
  } as const;
</script>

<OnEvents {onLibraryCreate} {onLibraryUpdate} {onLibraryDelete} />

<CommandPaletteDefaultProvider name={$t('external_libraries')} actions={[ScanAll, AddPath]} />

<AdminPageLayout breadcrumbs={[{ title: data.meta.title }]} actions={[ScanAll, AddPath]}>
  <Container size="large" center class="my-4">
    <div class="flex flex-col gap-4">
      <section class="rounded-2xl border border-[#D4D4D9] bg-white dark:border-immich-dark-gray dark:bg-immich-dark-gray/20">
        {#if managedFolders.length > 0}
          <div class="divide-y divide-[#EAEAEE] dark:divide-immich-dark-gray">
            {#each managedFolders as folder (folder.library.id + folder.path)}
              <div class="flex flex-col gap-3 px-5 py-4 md:flex-row md:items-center md:justify-between">
                <div class="min-w-0">
                  <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#F5F5F7] dark:bg-immich-dark-gray/70">
                      <svg viewBox="0 0 24 24" class="h-5 w-5 fill-none stroke-current text-[#626266] dark:text-immich-dark-fg/80">
                        <path d="M3 7.75A1.75 1.75 0 0 1 4.75 6h4.086c.464 0 .909.184 1.237.513l1.414 1.414c.328.329.773.513 1.237.513h6.526A1.75 1.75 0 0 1 21 10.19v7.06A1.75 1.75 0 0 1 19.25 19H4.75A1.75 1.75 0 0 1 3 17.25z" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
                      </svg>
                    </div>
                    <div class="min-w-0">
                      <Text fontWeight="medium" class="break-all">{folder.path}</Text>
                      <Text size="tiny" color="muted">{$t('import_path')}</Text>
                    </div>
                  </div>
                </div>

                <div class="flex shrink-0 gap-2">
                  <Button color="secondary" size="small" onclick={() => goto(Route.folders({ path: folder.path }))}>
                    {$t('open')}
                  </Button>
                  <Button color="danger" size="small" onclick={() => handleRemovePath(folder)}>
                    {$t('remove')}
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <div class="flex flex-col items-center justify-center gap-3 px-6 py-16 text-center">
            <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#F5F5F7] text-[#626266] dark:bg-immich-dark-gray/70 dark:text-immich-dark-fg/80">
              <svg viewBox="0 0 24 24" class="h-7 w-7 fill-none stroke-current">
                <path d="M3 7.75A1.75 1.75 0 0 1 4.75 6h4.086c.464 0 .909.184 1.237.513l1.414 1.414c.328.329.773.513 1.237.513h6.526A1.75 1.75 0 0 1 21 10.19v7.06A1.75 1.75 0 0 1 19.25 19H4.75A1.75 1.75 0 0 1 3 17.25z" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
              </svg>
            </div>
            <Text>{$t('no_libraries_message')}</Text>
            <div class="flex gap-2">
              <Button color="secondary" onclick={() => goto(Route.folders())}>{$t('skip_to_folders')}</Button>
              <Button onclick={handleAddPath}>{$t('add_path')}</Button>
            </div>
          </div>
        {/if}
      </section>

      {@render children?.()}
    </div>
  </Container>
</AdminPageLayout>
