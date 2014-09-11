from yajl_common cimport *

cdef extern from "yajl/yajl_parse.h":
    cdef enum yajl_status:
        yajl_status_ok,
        yajl_status_client_canceled,
        yajl_status_error

    const char * yajl_status_to_string(yajl_status code);

    ctypedef struct yajl_handle:
        pass

    ctypedef struct yajl_callbacks:
        bint (* yajl_null)(void * ctx)
        bint (* yajl_boolean)(void * ctx, int boolVal)
        bint (* yajl_integer)(void * ctx, long long integerVal)
        bint (* yajl_double)(void * ctx, double doubleVal)
        bint (* yajl_number)(void * ctx, const char * numberVal,
                            size_t numberLen)
        bint (* yajl_string)(void * ctx, const unsigned char * stringVal,
                            size_t stringLen)
        bint (* yajl_start_map)(void * ctx)
        bint (* yajl_map_key)(void * ctx, const unsigned char * key,
                             size_t stringLen)
        bint (* yajl_end_map)(void * ctx)
        bint (* yajl_start_array)(void * ctx)
        bint (* yajl_end_array)(void * ctx)
    
    yajl_handle yajl_alloc(const yajl_callbacks * callbacks,
                                    yajl_alloc_funcs * afs,
                                    void * ctx)
    
    cdef enum yajl_option:
        yajl_allow_comments = 0x01,
        yajl_dont_validate_strings = 0x02,
        yajl_allow_trailing_garbage = 0x04,
        yajl_allow_multiple_values = 0x08,
        yajl_allow_partial_values = 0x10
    
    int yajl_config(yajl_handle h, yajl_option opt, ...)
    void yajl_free(yajl_handle handle)
    yajl_status yajl_parse(yajl_handle hand,
                                    const unsigned char * jsonText,
                                    size_t jsonTextLength)
    yajl_status yajl_complete_parse(yajl_handle hand)
    unsigned char * yajl_get_error(yajl_handle hand, int verbose,
                                            const unsigned char * jsonText,
                                            size_t jsonTextLength)
    size_t yajl_get_bytes_consumed(yajl_handle hand)
    void yajl_free_error(yajl_handle hand, unsigned char * string)
