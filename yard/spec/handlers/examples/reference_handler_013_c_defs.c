VALUE
rb_str_cm(VALUE str)
{
}

VALUE
rb_str_im(VALUE str)
{
}

void
Init_String(void)
{
    rb_cString  = rb_define_class("String", rb_cObject);
    rb_define_singleton_method(rb_cString, "cm", rb_str_cm, -1);
    rb_define_method(rb_cString, "im", rb_str_im, 0);
}
