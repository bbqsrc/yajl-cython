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
    return parse_ret(instance.boolean(boolVal))

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

cdef class YajlParser:
    cdef Context* ctx
    cdef object _handler
    cdef yajl_handle hand

    def __cinit__(self, handler):
        self.ctx = <Context*> malloc(sizeof(Context))
        self.ctx.instance = <PyObject*>handler
        self.hand = yajl_alloc(get_callbacks(), NULL, self.ctx)
        Py_INCREF(handler)

    def __init__(self, handler):
        self._handler = handler

    def __dealloc__(self):
        Py_DECREF(self._handler)
        yajl_free(self.hand)
        free(self.ctx)

    def parse_chunk(self, chunk):
        if isinstance(chunk, str):
            chunk = chunk.encode('utf-8')

        if not isinstance(chunk, bytes):
            raise TypeError

        yajl_parse(self.hand, chunk, len(chunk)) 

def test():
    handler = YajlContentHandler()
    parser = YajlParser(handler)
    parser.parse_chunk("{")
    parser.parse_chunk('"foo": 2, "happy": 2')
    parser.parse_chunk('34}')
