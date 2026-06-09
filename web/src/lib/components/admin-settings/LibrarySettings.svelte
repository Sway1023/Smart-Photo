<script lang="ts">
  import { goto } from '$app/navigation';
  import SettingAccordion from '$lib/components/shared-components/settings/setting-accordion.svelte';
  import SettingInputField from '$lib/components/shared-components/settings/setting-input-field.svelte';
  import SettingSelect from '$lib/components/shared-components/settings/setting-select.svelte';
  import SettingSwitch from '$lib/components/shared-components/settings/setting-switch.svelte';
  import SettingButtonsRow from '$lib/components/shared-components/settings/SystemConfigButtonRow.svelte';
  import { SettingInputFieldType } from '$lib/constants';
  import FormatMessage from '$lib/elements/FormatMessage.svelte';
  import { featureFlagsManager } from '$lib/managers/feature-flags-manager.svelte';
  import { Route } from '$lib/route';
  import { systemConfigManager } from '$lib/managers/system-config-manager.svelte';
  import { Button, Link } from '@immich/ui';
  import { t } from 'svelte-i18n';
  import { fade } from 'svelte/transition';

  const disabled = $derived(featureFlagsManager.value.configFile);
  const config = $derived(systemConfigManager.value);
  let configToEdit = $state(systemConfigManager.cloneValue());

  let cronExpressionOptions = $derived([
    { text: $t('interval.night_at_midnight'), value: '0 0 * * *' },
    { text: $t('interval.night_at_twoam'), value: '0 2 * * *' },
    { text: $t('interval.day_at_onepm'), value: '0 13 * * *' },
    { text: $t('interval.hours', { values: { hours: 6 } }), value: '0 */6 * * *' },
  ]);
</script>

<div>
  <div in:fade={{ duration: 500 }}>
    <form autocomplete="off" onsubmit={(event) => event.preventDefault()}>
      <div class="ms-4 mt-4 flex flex-col gap-4">
        <div class="rounded-xl border border-[#D4D4D9] bg-[#F5F5F7] px-4 py-3 text-sm text-[#626266] dark:border-immich-dark-gray dark:bg-immich-dark-gray/40 dark:text-immich-dark-fg/80">
          <p>{$t('admin.library_folder_description')}</p>
          <div class="mt-3">
            <Button size="small" color="secondary" variant="ghost" onclick={() => goto(Route.libraries())}>
              {$t('external_libraries')}
            </Button>
          </div>
        </div>

        <SettingAccordion
          key="library-watching"
          title={$t('admin.library_watching_settings')}
          subtitle={$t('admin.library_watching_settings_description')}
        >
          <div class="ms-4 mt-4 flex flex-col gap-4">
            <SettingSwitch
              title={$t('admin.library_watching_enable_description')}
              {disabled}
              bind:checked={configToEdit.library.watch.enabled}
            />
          </div>
        </SettingAccordion>

        <SettingAccordion
          key="library-scanning"
          title={$t('admin.library_scanning')}
          subtitle={$t('admin.library_scanning_description')}
        >
          <div class="ms-4 mt-4 flex flex-col gap-4">
            <SettingSwitch
              title={$t('admin.library_scanning_enable_description')}
              {disabled}
              bind:checked={configToEdit.library.scan.enabled}
            />

            <SettingSelect
              options={cronExpressionOptions}
              disabled={disabled || !configToEdit.library.scan.enabled}
              name="expression"
              label={$t('admin.cron_expression_presets')}
              bind:value={configToEdit.library.scan.cronExpression}
            />

            <SettingInputField
              inputType={SettingInputFieldType.TEXT}
              required={true}
              disabled={disabled || !configToEdit.library.scan.enabled}
              label={$t('admin.cron_expression')}
              bind:value={configToEdit.library.scan.cronExpression}
              isEdited={configToEdit.library.scan.cronExpression !== config.library.scan.cronExpression}
            >
              {#snippet descriptionSnippet()}
                <p class="text-sm dark:text-immich-dark-fg">
                  <FormatMessage key="admin.cron_expression_description">
                    {#snippet children({ message })}
                      <Link
                        href="https://crontab.guru/#{configToEdit.library.scan.cronExpression.replaceAll(' ', '_')}"
                      >
                        {message}
                      </Link>
                    {/snippet}
                  </FormatMessage>
                </p>
              {/snippet}
            </SettingInputField>
          </div>
        </SettingAccordion>

        <SettingButtonsRow bind:configToEdit keys={['library']} {disabled} />
      </div>
    </form>
  </div>
</div>
