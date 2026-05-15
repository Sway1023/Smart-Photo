import { BadRequestException, Injectable } from '@nestjs/common';
import { ClassConstructor } from 'class-transformer';
import { SystemConfig } from 'src/config';
import { OnEvent, OnJob } from 'src/decorators';
import { AuthDto } from 'src/dtos/auth.dto';
import {
  mapQueueLegacy,
  mapQueuesLegacy,
  QueueResponseLegacyDto,
  QueuesResponseLegacyDto,
} from 'src/dtos/queue-legacy.dto';
import {
  QueueCommandDto,
  QueueDeleteDto,
  QueueJobResponseDto,
  QueueJobSearchDto,
  QueueResponseDto,
  QueueUpdateDto,
} from 'src/dtos/queue.dto';
import {
  BootstrapEventPriority,
  CronJob,
  DatabaseLock,
  ImmichWorker,
  JobName,
  JobStatus,
  QueueCleanType,
  QueueCommand,
  QueueName,
} from 'src/enum';
import { ArgOf } from 'src/repositories/event.repository';
import { BaseService } from 'src/services/base.service';
import { ConcurrentQueueName, JobItem } from 'src/types';
import { handlePromiseError } from 'src/utils/misc';

const asNightlyTasksCron = (config: SystemConfig) => {
  const [hours, minutes] = config.nightlyTasks.startTime.split(':').map(Number);
  return `${minutes} ${hours} * * *`;
};

@Injectable()
export class QueueService extends BaseService {
  private services: ClassConstructor<unknown>[] = [];
  private nightlyJobsLock = false;
  private readonly disabledQueues = new Set<QueueName>([
    QueueName.Workflow,
    QueueName.FaceDetection,
    QueueName.FacialRecognition,
    QueueName.SmartSearch,
    QueueName.DuplicateDetection,
    QueueName.Ocr,
  ]);

  @OnJob({ name: JobName.WorkflowRun, queue: QueueName.Workflow })
  async skipWorkflowRun(): Promise<JobStatus> {
    this.logger.warn('Skipping WorkflowRun job because workflows are disabled in this build');
    return JobStatus.Skipped;
  }

  private skipMlJob(name: string): JobStatus {
    this.logger.warn(`Skipping ${name} job because machine learning features are disabled in this build`);
    return JobStatus.Skipped;
  }

  private skipPersonJob(name: string): JobStatus {
    this.logger.warn(`Skipping ${name} job because person features are disabled in this build`);
    return JobStatus.Skipped;
  }

  @OnJob({ name: JobName.SmartSearchQueueAll, queue: QueueName.SmartSearch })
  async skipSmartSearchQueueAll(): Promise<JobStatus> {
    return this.skipMlJob(JobName.SmartSearchQueueAll);
  }

  @OnJob({ name: JobName.SmartSearch, queue: QueueName.SmartSearch })
  async skipSmartSearch(): Promise<JobStatus> {
    return this.skipMlJob(JobName.SmartSearch);
  }

  @OnJob({ name: JobName.AssetDetectDuplicatesQueueAll, queue: QueueName.DuplicateDetection })
  async skipDuplicateDetectionQueueAll(): Promise<JobStatus> {
    return this.skipMlJob(JobName.AssetDetectDuplicatesQueueAll);
  }

  @OnJob({ name: JobName.AssetDetectDuplicates, queue: QueueName.DuplicateDetection })
  async skipDuplicateDetection(): Promise<JobStatus> {
    return this.skipMlJob(JobName.AssetDetectDuplicates);
  }

  @OnJob({ name: JobName.OcrQueueAll, queue: QueueName.Ocr })
  async skipOcrQueueAll(): Promise<JobStatus> {
    return this.skipMlJob(JobName.OcrQueueAll);
  }

  @OnJob({ name: JobName.Ocr, queue: QueueName.Ocr })
  async skipOcr(): Promise<JobStatus> {
    return this.skipMlJob(JobName.Ocr);
  }

  @OnJob({ name: JobName.PersonCleanup, queue: QueueName.BackgroundTask })
  async skipPersonCleanup(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.PersonCleanup);
  }

  @OnJob({ name: JobName.AssetDetectFacesQueueAll, queue: QueueName.FaceDetection })
  async skipDetectFacesQueueAll(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.AssetDetectFacesQueueAll);
  }

  @OnJob({ name: JobName.AssetDetectFaces, queue: QueueName.FaceDetection })
  async skipDetectFaces(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.AssetDetectFaces);
  }

  @OnJob({ name: JobName.FacialRecognitionQueueAll, queue: QueueName.FacialRecognition })
  async skipFacialRecognitionQueueAll(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.FacialRecognitionQueueAll);
  }

  @OnJob({ name: JobName.FacialRecognition, queue: QueueName.FacialRecognition })
  async skipFacialRecognition(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.FacialRecognition);
  }

  @OnJob({ name: JobName.PersonFileMigration, queue: QueueName.Migration })
  async skipPersonFileMigration(): Promise<JobStatus> {
    return this.skipPersonJob(JobName.PersonFileMigration);
  }

  @OnEvent({ name: 'ConfigInit' })
  async onConfigInit({ newConfig: config }: ArgOf<'ConfigInit'>) {
    if (this.worker === ImmichWorker.Microservices) {
      this.updateConcurrency(config);
      return;
    }

    this.nightlyJobsLock = await this.databaseRepository.tryLock(DatabaseLock.NightlyJobs);
    if (this.nightlyJobsLock) {
      const cronExpression = asNightlyTasksCron(config);
      this.logger.debug(`Scheduling nightly jobs for ${cronExpression}`);
      this.cronRepository.create({
        name: CronJob.NightlyJobs,
        expression: cronExpression,
        start: true,
        onTick: () => handlePromiseError(this.handleNightlyJobs(), this.logger),
      });
    }
  }

  @OnEvent({ name: 'ConfigUpdate', server: true })
  onConfigUpdate({ newConfig: config }: ArgOf<'ConfigUpdate'>) {
    if (this.worker === ImmichWorker.Microservices) {
      this.updateConcurrency(config);
      return;
    }

    if (this.nightlyJobsLock) {
      const cronExpression = asNightlyTasksCron(config);
      this.logger.debug(`Scheduling nightly jobs for ${cronExpression}`);
      this.cronRepository.update({ name: CronJob.NightlyJobs, expression: cronExpression, start: true });
    }
  }

  @OnEvent({ name: 'AppBootstrap', priority: BootstrapEventPriority.JobService })
  onBootstrap() {
    this.jobRepository.setup(this.services);
    if (this.worker === ImmichWorker.Microservices) {
      this.jobRepository.startWorkers();
    }
  }

  private updateConcurrency(config: SystemConfig) {
    this.logger.debug(`Updating queue concurrency settings`);
    for (const queueName of Object.values(QueueName)) {
      let concurrency = 1;
      if (this.isConcurrentQueue(queueName)) {
        concurrency = config.job[queueName].concurrency;
      }
      this.logger.debug(`Setting ${queueName} concurrency to ${concurrency}`);
      this.jobRepository.setConcurrency(queueName, concurrency);
    }
  }

  setServices(services: ClassConstructor<unknown>[]) {
    this.services = services;
  }

  async runCommandLegacy(name: QueueName, dto: QueueCommandDto): Promise<QueueResponseLegacyDto> {
    this.logger.debug(`Handling command: queue=${name},command=${dto.command},force=${dto.force}`);

    switch (dto.command) {
      case QueueCommand.Start: {
        await this.start(name, dto);
        break;
      }

      case QueueCommand.Pause: {
        await this.jobRepository.pause(name);
        break;
      }

      case QueueCommand.Resume: {
        await this.jobRepository.resume(name);
        break;
      }

      case QueueCommand.Empty: {
        await this.jobRepository.empty(name);
        break;
      }

      case QueueCommand.ClearFailed: {
        const failedJobs = await this.jobRepository.clear(name, QueueCleanType.Failed);
        this.logger.debug(`Cleared failed jobs: ${failedJobs}`);
        break;
      }
    }

    const response = await this.getByName(name);

    return mapQueueLegacy(response);
  }

  async getAll(_auth: AuthDto): Promise<QueueResponseDto[]> {
    const queues = Object.values(QueueName).filter((name) => !this.disabledQueues.has(name));
    return Promise.all(queues.map((name) => this.getByName(name)));
  }

  async getAllLegacy(auth: AuthDto): Promise<QueuesResponseLegacyDto> {
    const responses = await this.getAll(auth);
    return mapQueuesLegacy(responses);
  }

  get(auth: AuthDto, name: QueueName): Promise<QueueResponseDto> {
    return this.getByName(name);
  }

  async update(auth: AuthDto, name: QueueName, dto: QueueUpdateDto): Promise<QueueResponseDto> {
    if (dto.isPaused === true) {
      if (name === QueueName.BackgroundTask) {
        throw new BadRequestException(`The BackgroundTask queue cannot be paused`);
      }
      await this.jobRepository.pause(name);
    }

    if (dto.isPaused === false) {
      await this.jobRepository.resume(name);
    }

    return this.getByName(name);
  }

  searchJobs(auth: AuthDto, name: QueueName, dto: QueueJobSearchDto): Promise<QueueJobResponseDto[]> {
    return this.jobRepository.searchJobs(name, dto);
  }

  async emptyQueue(auth: AuthDto, name: QueueName, dto: QueueDeleteDto) {
    await this.jobRepository.empty(name);
    if (dto.failed) {
      await this.jobRepository.clear(name, QueueCleanType.Failed);
    }
  }

  private async getByName(name: QueueName): Promise<QueueResponseDto> {
    const [statistics, isPaused] = await Promise.all([
      this.jobRepository.getJobCounts(name),
      this.jobRepository.isPaused(name),
    ]);
    return { name, isPaused, statistics };
  }

  private async start(name: QueueName, { force }: QueueCommandDto): Promise<void> {
    const isActive = await this.jobRepository.isActive(name);
    if (isActive) {
      throw new BadRequestException(`Job is already running`);
    }

    await this.eventRepository.emit('QueueStart', { name });

    switch (name) {
      case QueueName.VideoConversion: {
        return this.jobRepository.queue({ name: JobName.AssetEncodeVideoQueueAll, data: { force } });
      }

      case QueueName.StorageTemplateMigration: {
        return this.jobRepository.queue({ name: JobName.StorageTemplateMigration });
      }

      case QueueName.Migration: {
        return this.jobRepository.queue({ name: JobName.FileMigrationQueueAll });
      }

      case QueueName.SmartSearch: {
        return this.jobRepository.queue({ name: JobName.SmartSearchQueueAll, data: { force } });
      }

      case QueueName.DuplicateDetection: {
        return this.jobRepository.queue({ name: JobName.AssetDetectDuplicatesQueueAll, data: { force } });
      }

      case QueueName.MetadataExtraction: {
        return this.jobRepository.queue({ name: JobName.AssetExtractMetadataQueueAll, data: { force } });
      }

      case QueueName.Sidecar: {
        return this.jobRepository.queue({ name: JobName.SidecarQueueAll, data: { force } });
      }

      case QueueName.ThumbnailGeneration: {
        return this.jobRepository.queue({ name: JobName.AssetGenerateThumbnailsQueueAll, data: { force } });
      }

      case QueueName.Library: {
        return this.jobRepository.queue({ name: JobName.LibraryScanQueueAll, data: { force } });
      }

      case QueueName.BackupDatabase: {
        return this.jobRepository.queue({ name: JobName.DatabaseBackup, data: { force } });
      }

      case QueueName.Ocr: {
        return this.jobRepository.queue({ name: JobName.OcrQueueAll, data: { force } });
      }

      default: {
        throw new BadRequestException(`Invalid job name: ${name}`);
      }
    }
  }

  private isConcurrentQueue(name: QueueName): name is ConcurrentQueueName {
    return ![
      QueueName.FacialRecognition,
      QueueName.StorageTemplateMigration,
      QueueName.DuplicateDetection,
      QueueName.BackupDatabase,
    ].includes(name);
  }

  async handleNightlyJobs() {
    const config = await this.getConfig({ withCache: false });
    const jobs: JobItem[] = [];

    if (config.nightlyTasks.databaseCleanup) {
      jobs.push(
        { name: JobName.AssetDeleteCheck },
        { name: JobName.UserDeleteCheck },
        { name: JobName.MemoryCleanup },
        { name: JobName.SessionCleanup },
        { name: JobName.AuditTableCleanup },
        { name: JobName.AuditLogCleanup },
      );
    }

    if (config.nightlyTasks.generateMemories) {
      jobs.push({ name: JobName.MemoryGenerate });
    }

    if (config.nightlyTasks.syncQuotaUsage) {
      jobs.push({ name: JobName.UserSyncUsage });
    }

    if (config.nightlyTasks.missingThumbnails) {
      jobs.push({ name: JobName.AssetGenerateThumbnailsQueueAll, data: { force: false } });
    }

    await this.jobRepository.queueAll(jobs);
  }
}
