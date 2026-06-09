
```powershell
docker compose -f docker-compose.dev.yml up -d redis database
docker compose -f docker-compose.dev.yml up -d immich-server
```

查看容器运行状态

```powershell
docker compose -f docker-compose.dev.yml ps
```

查看 immich-server 日志

```powershell
docker compose -f docker-compose.dev.yml logs -f immich-server
```

后端代码变更后重启 immich-server

```powershell
docker compose -f docker-compose.dev.yml restart immich-server
```

停止并移除相关容器

```powershell
docker compose -f docker-compose.dev.yml down
```
