"""Model 层公共工具"""
import json


def parse_json_list(val):
    """解析 JSON 数组字符串, 容错返回 []"""
    if not val:
        return []
    try:
        return json.loads(val)
    except (json.JSONDecodeError, TypeError):
        return [val] if val else []


def parse_json_obj(val):
    """解析 JSON 对象字符串, 容错返回 {}"""
    if not val:
        return {}
    try:
        return json.loads(val)
    except (json.JSONDecodeError, TypeError):
        return {}


def dumps(val):
    """将 Python 对象序列化为 JSON 字符串（用于写入 Text 列）"""
    if val is None:
        return None
    return json.dumps(val, ensure_ascii=False)
