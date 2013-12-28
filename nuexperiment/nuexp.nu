


(class NUExperimentViewController
    (- (void) viewDidAppear:(BOOL) animated is 
        (super viewDidAppear:animated)

        (((((((UIView nu_animateWithDuration:.7 animations:(do ()
            ((self testview) setFrame:(list 0 100 50 50))
        )) nu_flattenMap:(do (value)
            (UIView nu_animateWithDuration:.5 animations:(do ()
                ((self testview) setFrame:(list 100 100 50 50))
            ))
        )) nu_flattenMap:(do (value)
            (UIView nu_animateWithDuration:.5 animations:(do ()
                ((self testview) setFrame:(list 100 0 50 50))
            ))  
        )) nu_flattenMap:(do (value)
            (UIView nu_animateWithDuration:.5 animations:(do ()
                ((self testview) setFrame:(list 0 0 50 50))
            ))  
        )) repeat) take:100) nu_subscribeCompleted:nil)
    )
)
