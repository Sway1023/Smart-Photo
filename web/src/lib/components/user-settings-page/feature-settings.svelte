<script lang="ts">
  import { goto } from '$app/navigation';
  import SettingAccordion from '$lib/components/shared-components/settings/setting-accordion.svelte';
  import { Route } from '$lib/route';
  import { preferences, user } from '$lib/stores/user.store';
  import { handleError } from '$lib/utils/handle-error';
  import { AssetOrder, updateMyPreferences } from '@immich/sdk';
  import { Button, Field, NumberInput, Select, Switch, toastManager } from '@immich/ui';
  import { t } from 'svelte-i18n';
  import { fade } from 'svelte/transition';

  // Albums
  let defaultAssetOrder = $state($preferences?.albums?.defaultAssetOrder ?? AssetOrder.Desc);

  // Folders
  let foldersEnabled = $state($preferences?.folders?.enabled ?? false);
  let foldersSidebar = $state($preferences?.folders?.sidebarWeb ?? false);

  // Memories
  let memoriesEnabled = $state($preferences?.memories?.enabled ?? true);
  let memoriesDuration = $state($preferences?.memories?.duration ?? 5);

  // People
  let peopleEnabled = $state($preferences?.people?.enabled ?? false);
  let peopleSidebar = $state($preferences?.people?.sidebarWeb ?? false);

  // Ratings
  let ratingsEnabled = $state($preferences?.ratings?.enabled ?? false);

  // Shared links
  let sharedLinksEnabled = $state($preferences?.sharedLinks?.enabled ?? true);
  let sharedLinkSidebar = $state($preferences?.sharedLinks?.sidebarWeb ?? false);

  // Tags
  let tagsEnabled = $state($preferences?.tags?.enabled ?? false);
  let tagsSidebar = $state($preferences?.tags?.sidebarWeb ?? false);

  const handleSave = async () => {
    try {
      const data = await updateMyPreferences({
        userPreferencesUpdateDto: {
          albums: { defaultAssetOrder },
          folders: { enabled: foldersEnabled, sidebarWeb: foldersSidebar },
          memories: { enabled: memoriesEnabled, duration: memoriesDuration },
          people: { enabled: peopleEnabled, sidebarWeb: peopleSidebar },
          ratings: { enabled: ratingsEnabled },
          sharedLinks: { enabled: sharedLinksEnabled, sidebarWeb: sharedLinkSidebar },
          tags: { enabled: tagsEnabled, sidebarWeb: tagsSidebar },
        },
      });

      $preferences = { ...data };

      toastManager.primary($t('saved_settings'));
    } catch (error) {
      handleError(error, $t('errors.unable_to_update_settings'));
    }
  };

  const onsubmit = (event: Event) => {
    event.preventDefault();
  };
</script>

<section class="my-4">
  <div in:fade={{ duration: 500 }}>
    <form autocomplete="off" {onsubmit}>
      <div class="sm:ms-4 md:ms-8 flex flex-col">
        <SettingAccordion key="albums" title={$t('albums')} subtitle={$t('albums_feature_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('albums_default_sort_order')} description={$t('albums_default_sort_order_description')}>
              <Select
                options={[
                  { label: $t('oldest_first'), value: AssetOrder.Asc },
                  { label: $t('newest_first'), value: AssetOrder.Desc },
                ]}
                bind:value={defaultAssetOrder}
              />
            </Field>
          </div>
        </SettingAccordion>

        <SettingAccordion key="folders" title={$t('folders')} subtitle={$t('folders_feature_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={foldersEnabled} />
            </Field>

            {#if foldersEnabled}
              <Field label={$t('sidebar')} description={$t('sidebar_display_description')}>
                <Switch bind:checked={foldersSidebar} />
              </Field>

              {#if $user.isAdmin}
                <div class="rounded-xl border border-[#D4D4D9] bg-[#F5F5F7] px-4 py-3 text-sm text-[#626266] dark:border-immich-dark-gray dark:bg-immich-dark-gray/40 dark:text-immich-dark-fg/80">
                  <p>{$t('admin.library_folder_description')}</p>
                  <div class="mt-3">
                    <Button size="small" color="secondary" variant="ghost" onclick={() => goto(Route.libraries())}>
                      {$t('external_libraries')}
                    </Button>
                  </div>
                </div>
              {/if}
            {/if}
          </div>
        </SettingAccordion>

        <SettingAccordion key="memories" title={$t('time_based_memories')} subtitle={$t('photos_from_previous_years')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={memoriesEnabled} />
            </Field>

            <Field label={$t('duration')} description={$t('time_based_memories_duration')}>
              <NumberInput bind:value={memoriesDuration} />
            </Field>
          </div>
        </SettingAccordion>

        <SettingAccordion key="people" title={$t('people')} subtitle={$t('people_feature_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={peopleEnabled} />
            </Field>

            {#if peopleEnabled}
              <Field label={$t('sidebar')} description={$t('sidebar_display_description')}>
                <Switch bind:checked={peopleSidebar} />
              </Field>
            {/if}
          </div>
        </SettingAccordion>

        <SettingAccordion key="rating" title={$t('rating')} subtitle={$t('rating_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={ratingsEnabled} />
            </Field>
          </div>
        </SettingAccordion>

        <SettingAccordion key="shared-links" title={$t('shared_links')} subtitle={$t('shared_links_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={sharedLinksEnabled} />
            </Field>

            {#if sharedLinksEnabled}
              <Field label={$t('sidebar')} description={$t('sidebar_display_description')}>
                <Switch bind:checked={sharedLinkSidebar} />
              </Field>
            {/if}
          </div>
        </SettingAccordion>

        <SettingAccordion key="tags" title={$t('tags')} subtitle={$t('tag_feature_description')}>
          <div class="sm:ms-4 mt-4 flex flex-col gap-4">
            <Field label={$t('enable')}>
              <Switch bind:checked={tagsEnabled} />
            </Field>

            {#if tagsEnabled}
              <Field label={$t('sidebar')} description={$t('sidebar_display_description')}>
                <Switch bind:checked={tagsSidebar} />
              </Field>
            {/if}
          </div>
        </SettingAccordion>
        <div class="flex justify-end mt-4">
          <Button shape="round" type="submit" size="small" onclick={() => handleSave()}>{$t('save')}</Button>
        </div>
      </div>
    </form>
  </div>
</section>
