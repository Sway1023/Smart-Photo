<script lang="ts">
  import { page } from '$app/stores';
  import ChangePinCodeSettings from '$lib/components/user-settings-page/PinCodeSettings.svelte';
  import FeatureSettings from '$lib/components/user-settings-page/feature-settings.svelte';
  import UserUsageStatistic from '$lib/components/user-settings-page/user-usage-statistic.svelte';
  import { OpenQueryParam, QueryParameter } from '$lib/constants';
  import { featureFlagsManager } from '$lib/managers/feature-flags-manager.svelte';
  import { user } from '$lib/stores/user.store';
  import { oauth } from '$lib/utils';
  import { type ApiKeyResponseDto, type SessionResponseDto } from '@immich/sdk';
  import {
    mdiAccountGroupOutline,
    mdiAccountOutline,
    mdiCogOutline,
    mdiFeatureSearchOutline,
    mdiFormTextboxPassword,
    mdiServerOutline,
    mdiTwoFactorAuthentication,
  } from '@mdi/js';
  import { t } from 'svelte-i18n';
  import SettingAccordionState from '../shared-components/settings/setting-accordion-state.svelte';
  import SettingAccordion from '../shared-components/settings/setting-accordion.svelte';
  import AppSettings from './app-settings.svelte';
  import ChangePasswordSettings from './change-password-settings.svelte';
  import OAuthSettings from './oauth-settings.svelte';
  import PartnerSettings from './partner-settings.svelte';
  import UserProfileSettings from './user-profile-settings.svelte';

  interface Props {
    keys?: ApiKeyResponseDto[];
    sessions?: SessionResponseDto[];
  }

  let { keys = $bindable([]), sessions = $bindable([]) }: Props = $props();

  let oauthOpen =
    oauth.isCallback(globalThis.location) ||
    $page.url.searchParams.get(QueryParameter.OPEN_SETTING) === OpenQueryParam.OAUTH;
</script>

<SettingAccordionState queryParam={QueryParameter.IS_OPEN}>
  <SettingAccordion
    icon={mdiCogOutline}
    key="app-settings"
    title={$t('app_settings')}
    subtitle={$t('manage_the_app_settings')}
  >
    <AppSettings />
  </SettingAccordion>

  <SettingAccordion icon={mdiAccountOutline} key="account" title={$t('account')} subtitle={$t('manage_your_account')}>
    <UserProfileSettings />
  </SettingAccordion>

  <SettingAccordion
    icon={mdiServerOutline}
    key="user-usage-info"
    title={$t('user_usage_stats')}
    subtitle={$t('user_usage_stats_description')}
  >
    <UserUsageStatistic />
  </SettingAccordion>

  <SettingAccordion
    icon={mdiFeatureSearchOutline}
    key="feature"
    title={$t('features')}
    subtitle={$t('features_setting_description')}
  >
    <FeatureSettings />
  </SettingAccordion>

  {#if featureFlagsManager.value.oauth}
    <SettingAccordion
      icon={mdiTwoFactorAuthentication}
      key={OpenQueryParam.OAUTH}
      title={$t('oauth')}
      subtitle={$t('manage_your_oauth_connection')}
      isOpen={oauthOpen || undefined}
    >
      <OAuthSettings user={$user} />
    </SettingAccordion>
  {/if}

  <SettingAccordion
    icon={mdiFormTextboxPassword}
    key="password"
    title={$t('password')}
    subtitle={$t('change_your_password')}
  >
    <ChangePasswordSettings />
  </SettingAccordion>

  <SettingAccordion
    icon={mdiAccountGroupOutline}
    key="partner-sharing"
    title={$t('partner_sharing')}
    subtitle={$t('manage_sharing_with_partners')}
  >
    <PartnerSettings user={$user} />
  </SettingAccordion>
</SettingAccordionState>
