.global tls_ptr
tls_ptr:
    mrs x0, tpidrro_el0
    ret

