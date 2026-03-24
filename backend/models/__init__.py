# 导入所有 Model 以便 db.create_all() 发现表结构
from .user import User, Token                          # noqa: F401
from .employer_profile import EmployerProfile          # noqa: F401
from .translator_profile import TranslatorProfile      # noqa: F401
from .availability_slot import AvailabilitySlot        # noqa: F401
from .translation_request import TranslationRequest    # noqa: F401
from .quote import Quote                               # noqa: F401
from .order import Order                               # noqa: F401
from .order_timeline import OrderTimeline              # noqa: F401
from .favorite import Favorite                         # noqa: F401
from .review import Review                             # noqa: F401
from .conversation import Conversation                 # noqa: F401
from .message import Message                           # noqa: F401
from .notification import Notification                 # noqa: F401
from .aftersale import Aftersale                       # noqa: F401
