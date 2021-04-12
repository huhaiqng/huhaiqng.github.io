#### 安装

安装 celery

```
pip install -U Celery
```

安装 celery redis

```
pip install "celery[redis]"
```



#### Worker

后台启动

```
# 前台
celery -A tasks worker --loglevel=INFO
# 后台
celery multi start worker -A [project-name] --loglevel=info
```

停止

```
celery multi stop worker -A [project-name] --loglevel=info
```

重启

```
celery multi restart worker -A [project-name] --loglevel=info
```



#### django-celery-beat

> 注意：项目在 Windows 上无法运行任务，在CentOS 7 上正常运行。
>
> 参考博文：http://www.starky.ltd/2020/05/08/task-schedule-system-with-django-celery-beat/

配置运行环境

```
$ python -m venv env
$ source ./env/bin/activate
$ pip install django-celery-beat django-celery-results redis
```

修改 schedule_task/settings.py 配置文件

```
ALLOWED_HOSTS = ['*',]

INSTALLED_APPS = [
    ...
    'schedules',
    'django_celery_results',
    'django_celery_beat'
]

LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = 'Asia/Shanghai'

CELERY_RESULT_BACKEND = 'django-db'
CELERY_BROKER_URL = 'redis://192.168.40.159:6379/3'
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'
```

数据库迁移，创建超级用户

```
$ python manage.py migrate
$ python manage.py createsuperuser
```

创建文件 schedule_task/celery.py

```
from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'schedule_task.settings')
app = Celery('schedule_task')

# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()
```

修改文件 schedule_task/__init__.py

```
from __future__ import absolute_import, unicode_literals

# This will make sure the app is always imported when
# Django starts so that shared_task will use this app.
from .celery import app as celery_app

__all__ = ('celery_app',)
```

创建文件 schedules/tasks.py

```
from __future__ import absolute_import, unicode_literals
from celery import shared_task

@shared_task(bind=True)
def debug_task(self):
    return f'Hello Celery, the task id is: {self.request.id}'
```

启动服务

- web 服务：python manage.py runserver 0.0.0.0:8000
- Celery Worker：celery multi start -A schedule_task worker -l info
- Celery Beat：celery -A schedule_task beat -l info