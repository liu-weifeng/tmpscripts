#!/bin/bash
# 直接通过 sysfs 配置，不使用水位线

DAMON="/sys/kernel/mm/damon/admin"

# 先关闭 DAMON_RECLAIM
echo N > /sys/module/damon_reclaim/parameters/enabled 2>/dev/null

# 清理
echo 0 > $DAMON/kdamonds/nr_kdamonds 2>/dev/null

# 创建配置
echo 1 > $DAMON/kdamonds/nr_kdamonds
echo 1 > $DAMON/kdamonds/0/contexts/nr_contexts
echo paddr > $DAMON/kdamonds/0/contexts/0/operations

CTX="$DAMON/kdamonds/0/contexts/0"

echo 5000 > $CTX/monitoring_attrs/intervals/sample_us
echo 100000 > $CTX/monitoring_attrs/intervals/aggr_us
echo 1000000 > $CTX/monitoring_attrs/intervals/update_us

echo 1 > $CTX/schemes/nr_schemes
SCHEME="$CTX/schemes/0"

echo 0 > $SCHEME/access_pattern/sz/min
echo 0 > $SCHEME/access_pattern/sz/max
echo 0 > $SCHEME/access_pattern/nr_accesses/min
echo 0 > $SCHEME/access_pattern/nr_accesses/max
echo 10000000 > $SCHEME/access_pattern/age/min  # 10秒
echo 0 > $SCHEME/access_pattern/age/max

echo pageout > $SCHEME/action

echo 10000 > $SCHEME/quotas/ms
echo 134217728 > $SCHEME/quotas/bytes
echo 1000 > $SCHEME/quotas/reset_interval_ms

# 不设置水位线（或设为 none）
echo none > $SCHEME/watermarks/metric

echo on > $DAMON/kdamonds/0/state

echo "Started. Monitoring stats:"
watch -n 2 "cat $SCHEME/stats/nr_tried; cat $SCHEME/stats/sz_applied"
