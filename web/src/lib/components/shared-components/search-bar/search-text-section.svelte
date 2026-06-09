<script lang="ts">
  import { Field, Input, Text } from '@immich/ui';
  import { t } from 'svelte-i18n';

  interface Props {
    query: string | undefined;
    queryType?: 'metadata' | 'description';
  }

  let { query = $bindable(), queryType = $bindable('metadata') }: Props = $props();
</script>

<section>
  <fieldset>
    <Text class="mb-2" fontWeight="medium">{$t('search_type')}</Text>
    <div class="flex flex-wrap gap-x-5 gap-y-2 my-2">
      <label class="flex items-center gap-2 text-sm">
        <input type="radio" name="query-type" bind:group={queryType} value="metadata" />
        {$t('file_name_or_extension')}
      </label>
      <label class="flex items-center gap-2 text-sm">
        <input type="radio" name="query-type" bind:group={queryType} value="description" />
        {$t('description')}
      </label>
    </div>
  </fieldset>

  {#if queryType === 'metadata'}
    <Field label={$t('search_by_filename')}>
      <Input type="text" placeholder={$t('search_by_filename_example')} bind:value={query} />
    </Field>
  {:else}
    <Field label={$t('search_by_description')}>
      <Input type="text" placeholder={$t('search_by_description_example')} bind:value={query} />
    </Field>
  {/if}
</section>
