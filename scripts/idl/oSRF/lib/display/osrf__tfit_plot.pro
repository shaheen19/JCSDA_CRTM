;+
; NAME:
;       OSRF::Plot
;
; PURPOSE:
;       The OSRF::Plot procedure method displays a valid OSRF object.
;
; CALLING SEQUENCE:
;       Obj->[OSRF::]Plot, $
;         Debug=Debug  ; Input keyword
;
; INPUT KEYWORD PARAMETERS:
;       Debug:       Set this keyword for debugging.
;                    If NOT SET => Error handler is enabled. (DEFAULT)
;                       SET     => Error handler is disabled; Routine
;                                  traceback output is enabled.
;                    UNITS:      N/A
;                    TYPE:       INTEGER
;                    DIMENSION:  Scalar
;                    ATTRIBUTES: INTENT(IN), OPTIONAL
;
; INCLUDE FILES:
;       osrf_parameters: Include file containing OSRF specific
;                        parameter value definitions.
;
;       osrf_pro_err_handler: Error handler code for OSRF procedures.
;
; EXAMPLE:
;       Given an instance of a OSRF object,
;
;         IDL> HELP, x
;         X               OBJREF    = <ObjHeapVar8(OSRF)>
;
;       the data is plotted like so:
;
;         IDL> x->Plot
;
; CREATION HISTORY:
;       Written by:     Paul van Delst, 20-Apr-2009
;                       paul.vandelst@noaa.gov
;
;-

PRO OSRF::Tfit_Plot, $
  Debug     = debug , $  ; Input keyword
  Color     = color , $  ; Input keyword
  Owin      = owin  , $  ; Input keyword
  gTitle    = gTitle, $  ; Input keyword
  EPS       = eps   , $  ; Input keyword (increase font size for eps output)
  _EXTRA    = extra

  ; Set up
  COMPILE_OPT HIDDEN
  ; ...OSRF parameters
  @osrf_parameters
  ; ...Set up error handler
  @osrf_pro_err_handler
  ; ...ALL *input* pointers must be associated
  IF ( NOT self.Associated(Debug=debug) ) THEN $
    MESSAGE, 'Some or all input OSRF pointer members are NOT associated.', $
             NONAME=MsgSwitch, NOPRINT=MsgSwitch
  ; ...Process keywords
  IF ( KEYWORD_SET(eps) ) THEN BEGIN
    create_window = TRUE
  ENDIF ELSE BEGIN
    IF ( KEYWORD_SET(owin) ) THEN BEGIN
      create_window = ~ ISA(owin,'GraphicsWin')
    ENDIF ELSE BEGIN
      create_window = TRUE
    ENDELSE
  ENDELSE


  ; Get the srf info and Tdata
  self.Get_Property, $
    Debug       = debug      , $
    n_Bands     = n_bands    , $
    Channel     = channel    , $
    Sensor_Id   = sensor_id  , $
    Sensor_Type = sensor_type, $
    poly_Tdata  = poly_tdata
  T    = poly_tdata["T"]
  Teff = poly_tdata["Teff"]
  Tfit = poly_tdata["Tfit"]


  ; Set the graphics window
  IF ( create_window ) THEN $
    owin = WINDOW( WINDOW_TITLE = sensor_id+' channel '+STRTRIM(channel,2)+' (Teff-Tfit) residuals', $
                   BUFFER = KEYWORD_SET(eps) )
  owin.SetCurrent
  owin.Erase
  ; ...Save it
  self.twRef = owin
  ; ...Set some plotting parameters
  font_size = KEYWORD_SET(eps) ? EPS_FONT_SIZE : WIN_FONT_SIZE
  xticklen  = 0.02
  yticklen  = 0.02
  margin    = KEYWORD_SET(eps) ? [0.2, 0.15, 0.05, 0.1] : [0.15, 0.1, 0.05, 0.1]
  
  
  ; Generate the titles
  ; ...The plot title
  IF ( self.Flag_Is_Set(IS_DIFFERENCE_FLAG, Debug=debug) ) THEN $
    dtitle = 'difference' $
  ELSE $
    dtitle = ''
  IF ( KEYWORD_SET(gTitle) ) THEN $
    title = "T$_{fit}$ residual " + dtitle + " for " + $
            "channel "+STRTRIM(channel,2) $
  ELSE $
    title = "T$_{fit}$ residual " + dtitle + " for " + $
            STRTRIM(sensor_id,2)+" channel "+STRTRIM(channel,2)
  ; ...The yaxis title
  IF ( self.Flag_Is_Set(IS_DIFFERENCE_FLAG, Debug=debug) ) THEN $
    ytitle = '$\Delta$T$_{eff}$ - $\Delta$T$_{fit}$ (K)' $
  ELSE $
    ytitle = 'T$_{eff}$ - T$_{fit}$ (K)'
  

  ; Plot the residuals
  self.tpRef = PLOT( $
    T,Teff - tfit, $
    XTITLE         = 'Temperature (K)', $
    YTITLE         = ytitle, $
    TITLE          = title, $
    FONT_SIZE      = font_size, $              
    XTICKLEN       = xticklen, $
    XTICKFONT_SIZE = font_size, $
    YTICKLEN       = yticklen, $
    MARGIN         = margin, $
    CURRENT        = owin, $
    COLOR          = color, $
    _EXTRA         = extra)
  !NULL = PLOT(self.tpRef.Xrange,[0,0], $
               LINESTYLE = 'dashed', $
               OVERPLOT  = self.tpRef)

END
