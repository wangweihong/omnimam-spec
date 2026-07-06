# Changelog

## 2026-07-06

- 收敛 S2 HTTP 状态码规则，仅允许 `200`、`404`、`500` 和真实重定向 `3xx`，业务成功或失败统一通过 `code` / `value` 判断。
- 同步将 `application-platform` 与 `task-center` 现有业务错误码契约改为 HTTP `200`，避免继续使用 `400`、`403`、`409` 表达业务错误。
