from yajl_parse cimport *
from cpython.ref cimport PyObject, Py_DECREF, Py_INCREF
from libc.stdlib cimport malloc, free

class YajlContentHandler:
    def null(self):
        return NotImplemented

    def boolean(self, val):
        return NotImplemented

    def integer(self, val):
        return NotImplemented

    def double(self, val):
        return NotImplemented

    def number(self, val):
        return NotImplemented

    def string(self, val):
        return NotImplemented
   
    def start_map(self):
        return NotImplemented
   
    def map_key(self, val):
        return NotImplemented

    def end_map(self):
        return NotImplemented

    def start_array(self):
        return NotImplemented

    def end_array(self):
        return NotImplemented

cdef struct Context:
    PyObject* instance 

cdef object get_instance(void* ctx):
    cdef Context* context
    context = <Context*> ctx
    cdef object instance = <object>context.instance
    return instance

cdef bint parse_ret(ret):
    if ret == 0:
        ret = False
    if ret is not False:
        ret = True
    return ret

cdef bint yajl_null(void* ctx):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.null())

cdef bint yajl_boolean(void* ctx, int boolVal):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.boolean(<bint>boolVal))

cdef bint yajl_integer(void* ctx, long long integerVal):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.integer(integerVal))

cdef bint yajl_double(void* ctx, double doubleVal):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.double(doubleVal))

cdef bint yajl_number(void* ctx, const char* numberVal, size_t numberLen):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.number(numberVal[:numberLen]))

cdef bint yajl_string(void* ctx, const unsigned char* stringVal, size_t stringLen):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.string(stringVal[:stringLen]))

cdef bint yajl_start_map(void* ctx):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.start_map())

cdef bint yajl_map_key(void* ctx, const unsigned char* key, size_t stringLen):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.map_key(key[:stringLen]))

cdef bint yajl_end_map(void* ctx):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.end_map())

cdef bint yajl_start_array(void* ctx):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.start_array())

cdef bint yajl_end_array(void* ctx):
    cdef object instance = get_instance(ctx)
    return parse_ret(instance.end_array())

cdef yajl_callbacks* get_callbacks():
    cdef yajl_callbacks* cb = <yajl_callbacks*>malloc(sizeof(yajl_callbacks))
    if cb == <yajl_callbacks*>NULL:
        raise MemoryError
    cb.yajl_null = yajl_null
    cb.yajl_boolean = yajl_boolean
    cb.yajl_integer = yajl_integer
    cb.yajl_double = yajl_double
    cb.yajl_number = yajl_number
    cb.yajl_string = yajl_string
    cb.yajl_start_map = yajl_start_map
    cb.yajl_map_key = yajl_map_key
    cb.yajl_end_map = yajl_end_map
    cb.yajl_start_array = yajl_start_array
    cb.yajl_end_array = yajl_end_array
    return cb

cdef get_error_string(yajl_handle hand, data):
    cdef unsigned char * cerr
    cerr = yajl_get_error(hand, 1, data, len(data))
    err = cerr[:]
    yajl_free_error(hand, cerr)
    return err

class ParseError(Exception):
    def __init__(self, msg):
        msg = msg.decode('utf-8').split(': ', 1)[1]
        super().__init__(msg)

class ParseClientCanceled(Exception):
    pass

cdef class YajlParser:
    cdef Context* ctx
    cdef object _handler
    cdef yajl_handle hand

    def __cinit__(self, handler, **cfg):
        Py_INCREF(handler)
        self.ctx = <Context*> malloc(sizeof(Context))
        if self.ctx == <Context*>NULL:
            raise MemoryError
        self.ctx.instance = <PyObject*>handler
        self.hand = yajl_alloc(get_callbacks(), NULL, self.ctx)
        if self.hand == <yajl_handle>NULL:
            raise MemoryError

        if len(cfg) > 0:
            if cfg.get('allow_comments', False):
                yajl_config(self.hand, yajl_allow_comments, 1)
            if cfg.get('dont_validate_strings', False):
                yajl_config(self.hand, yajl_dont_validate_strings, 1)
            if cfg.get('allow_trailing_garbage', False):
                yajl_config(self.hand, yajl_allow_trailing_garbage, 1)
            if cfg.get('allow_multiple_values', False):
                yajl_config(self.hand, yajl_allow_multiple_values, 1)
            if cfg.get('allow_partial_values', False):
                yajl_config(self.hand, yajl_allow_partial_values, 1)

    def __init__(self, handler, **cfg):
        self._handler = handler

    def __dealloc__(self):
        Py_DECREF(self._handler)
        yajl_free(self.hand)
        free(self.ctx)

    def parse(self, data):
        self.parse_chunk(data)

        status = yajl_complete_parse(self.hand)

        if status == yajl_status_client_canceled:
            raise ParseClientCanceled()

        if status == yajl_status_error:
            raise ParseError(get_error_string(self.hand, data))

    def parse_chunk(self, chunk):
        cdef unsigned char * cerr
        
        if isinstance(chunk, str):
            chunk = chunk.encode('utf-8')

        if not isinstance(chunk, bytes):
            raise TypeError

        status = yajl_parse(self.hand, chunk, len(chunk))

        if status == yajl_status_client_canceled:
            raise ParseClientCanceled()

        if status == yajl_status_error:
            raise ParseError(get_error_string(self.hand, chunk))

