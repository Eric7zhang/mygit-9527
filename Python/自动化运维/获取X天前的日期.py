from datetime import datetime, timedelta

# 获取当前日期
current_date = datetime.now()

# 计算84天前的日期
days_before = 84
date_before = current_date - timedelta(days=days_before)

# 格式化输出日期
formatted_date = date_before.strftime('%Y-%m-%d')

print(f"84天前的日期是: {formatted_date}")