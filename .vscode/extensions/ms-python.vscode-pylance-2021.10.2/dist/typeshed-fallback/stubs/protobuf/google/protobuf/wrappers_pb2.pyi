"""
@generated by mypy-protobuf.  Do not edit manually!
isort:skip_file
"""
import builtins
import google.protobuf.descriptor
import google.protobuf.message
import typing
import typing_extensions

DESCRIPTOR: google.protobuf.descriptor.FileDescriptor = ...

# Wrapper message for `double`.
#
# The JSON representation for `DoubleValue` is JSON number.
class DoubleValue(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The double value.
    value: builtins.float = ...
    def __init__(self,
        *,
        value : builtins.float = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___DoubleValue = DoubleValue

# Wrapper message for `float`.
#
# The JSON representation for `FloatValue` is JSON number.
class FloatValue(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The float value.
    value: builtins.float = ...
    def __init__(self,
        *,
        value : builtins.float = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___FloatValue = FloatValue

# Wrapper message for `int64`.
#
# The JSON representation for `Int64Value` is JSON string.
class Int64Value(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The int64 value.
    value: builtins.int = ...
    def __init__(self,
        *,
        value : builtins.int = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___Int64Value = Int64Value

# Wrapper message for `uint64`.
#
# The JSON representation for `UInt64Value` is JSON string.
class UInt64Value(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The uint64 value.
    value: builtins.int = ...
    def __init__(self,
        *,
        value : builtins.int = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___UInt64Value = UInt64Value

# Wrapper message for `int32`.
#
# The JSON representation for `Int32Value` is JSON number.
class Int32Value(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The int32 value.
    value: builtins.int = ...
    def __init__(self,
        *,
        value : builtins.int = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___Int32Value = Int32Value

# Wrapper message for `uint32`.
#
# The JSON representation for `UInt32Value` is JSON number.
class UInt32Value(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The uint32 value.
    value: builtins.int = ...
    def __init__(self,
        *,
        value : builtins.int = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___UInt32Value = UInt32Value

# Wrapper message for `bool`.
#
# The JSON representation for `BoolValue` is JSON `true` and `false`.
class BoolValue(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The bool value.
    value: builtins.bool = ...
    def __init__(self,
        *,
        value : builtins.bool = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___BoolValue = BoolValue

# Wrapper message for `string`.
#
# The JSON representation for `StringValue` is JSON string.
class StringValue(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The string value.
    value: typing.Text = ...
    def __init__(self,
        *,
        value : typing.Text = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___StringValue = StringValue

# Wrapper message for `bytes`.
#
# The JSON representation for `BytesValue` is JSON string.
class BytesValue(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor = ...
    VALUE_FIELD_NUMBER: builtins.int
    # The bytes value.
    value: builtins.bytes = ...
    def __init__(self,
        *,
        value : builtins.bytes = ...,
        ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal[u"value",b"value"]) -> None: ...
global___BytesValue = BytesValue
