#!/bin/bash

# 先关闭 DAMON_RECLAIM
echo N > /sys/module/damon_reclaim/parameters/enabled 2>/dev/null
sleep 1

DAMON="/sys/kernel/mm/damon/admin"

# 检查 sysfs 是否存在
if [ ! -d "$DAMON" ]; then
    echo "Error: $DAMON not found"
    echo "Check: CONFIG_DAMON_SYSFS=y"
    exit 1
fi

# 清理旧配置
echo off > $DAMON/kdamonds/0/state 2>/dev/null
echo 0 > $DAMON/kdamonds/nr_kdamonds 2>/dev/null

# 创建 kdamond
echo 1 > $DAMON/kdamonds/nr_kdamonds

# 创建 context
echo 1 > $DAMON/kdamonds/0/contexts/nr_contexts
echo paddr > $DAMON/kdamonds/0/contexts/0/operations

CTX="$DAMON/kdamonds/0/contexts/0"

# 监控参数
echo 5000 > $CTX/monitoring_attrs/intervals/sample_us
echo 100000 > $CTX/monitoring_attrs/intervals/aggr_us
echo 1000000 > $CTX/monitoring_attrs/intervals/update_us
echo 10 > $CTX/monitoring_attrs/nr_regions/min
echo 1000 > $CTX/monitoring_attrs/nr_regions/max

# 创建 scheme
echo 1 > $CTX/schemes/nr_schemes
SCHEME="$CTX/schemes/0"

# 访问模式：冷页
echo 0 > $SCHEME/access_pattern/sz/min
echo 0 > $SCHEME/access_pattern/sz/max
echo 0 > $SCHEME/access_pattern/nr_accesses/min
echo 0 > $SCHEME/access_pattern/nr_accesses/max
echo 10000000 > $SCHEME/access_pattern/age/min   # 10秒
echo 0 > $SCHEME/access_pattern/age/max

# 
echo pageout > $SCHEME/action

# 配额
echo 10000 > $SCHEME/quotas/ms
echo 134217728 > $SCHEME/quotas/bytes
echo 1000 > $SCHEME/quotas/reset_interval_ms

# 不使用水位线
echo none > $SCHEME/watermarks/metric

echo on > $DAMON/kdamonds/0/state

echo "Started!"
echo ""

for i in {1..30}; do
    tried=$(cat $SCHEME/stats/nr_tried 2>/dev/null || echo 0)
    applied=$(cat $SCHEME/stats/nr_applied 2>/dev/null || echo 0)
    sz_applied=$(cat $SCHEME/stats/sz_applied 2>/dev/null || echo 0)
    sz_h=$(numfmt --to=iec $sz_applied 2>/dev/null || echo $sz_applied)
    
    echo "[$i] tried=$tried, applied=$applied, sz_applied=$sz_h"
    sleep 2
done


