!
! CRTM_AtmScatter_Define
!
! Module defining the CRTM AtmScatter structure and containing
! routines to manipulate it.
!
! CALLING SEQUENCE:
!       USE CRTM_AtmScatter_Define
!
!
! CREATION HISTORY:
!       Written by:     Yong Han,       NOAA/NESDIS;     Yong.Han@noaa.gov
!                       Quanhua Liu,    QSS Group, Inc;  Quanhua.Liu@noaa.gov
!                       Paul van Delst, CIMSS/SSEC;      paul.vandelst@ssec.wisc.edu
!                       02-Apr-2004
!

MODULE CRTM_AtmScatter_Define

  ! -----------------
  ! Environment setup
  ! -----------------
  ! Module use
  USE Type_Kinds,      ONLY: fp=>fp_kind
  USE Message_Handler, ONLY: SUCCESS, FAILURE, Display_Message
  USE CRTM_Parameters, ONLY: ZERO, SET
  ! Disable implicit typing
  IMPLICIT NONE


  ! ------------
  ! Visibilities
  ! ------------
  ! Everything private by default
  PRIVATE
  ! CRTM_AtmScatter structure definition
  PUBLIC :: CRTM_AtmScatter_type
  ! CRTM_AtmScatter structure routines
  PUBLIC :: CRTM_Associated_AtmScatter
  PUBLIC :: CRTM_Destroy_AtmScatter
  PUBLIC :: CRTM_Allocate_AtmScatter
  PUBLIC :: CRTM_Assign_AtmScatter


  ! -----------------
  ! Module parameters
  ! -----------------
  ! RCS Id for the module
  CHARACTER(*), PARAMETER :: MODULE_RCS_ID = &
  '$Id$'

  
  ! -----------------------------------------
  ! Scattering structure data type definition
  ! -----------------------------------------
  TYPE :: CRTM_AtmScatter_type
    INTEGER :: n_Allocates = 0
    ! Dimensions
    INTEGER :: n_Layers           = 0  ! K dimension
    INTEGER :: Max_Legendre_Terms = 0  ! Ic dimension
    INTEGER :: n_Legendre_Terms   = 0  ! IcUse dimension
    INTEGER :: Max_Phase_Elements = 0  ! Ip dimension
    INTEGER :: n_Phase_Elements   = 0  ! IpUse dimension
    ! Algorithm specific members
    REAL(fp), DIMENSION(:,:,:), POINTER :: Phase_Coefficient => NULL()  ! 0:Ic x Ip x K
    INTEGER :: lOffset = 0   ! start position in array for Legendre coefficients 
    ! Mandatory members
    REAL(fp), DIMENSION(:), POINTER :: Optical_Depth         => NULL() ! K
    REAL(fp), DIMENSION(:), POINTER :: Single_Scatter_Albedo => NULL() ! K
    REAL(fp), DIMENSION(:), POINTER :: Asymmetry_Factor      => NULL() ! K
    REAL(fp), DIMENSION(:), POINTER :: Delta_Truncation      => NULL() ! K
  END TYPE CRTM_AtmScatter_type


CONTAINS





!##################################################################################
!##################################################################################
!##                                                                              ##
!##                          ## PRIVATE MODULE ROUTINES ##                       ##
!##                                                                              ##
!##################################################################################
!##################################################################################

!----------------------------------------------------------------------------------
!
! NAME:
!       CRTM_Clear_AtmScatter
!
! PURPOSE:
!       Subroutine to clear the scalar members of a CRTM_AtmScatter structure.
!
! CALLING SEQUENCE:
!       CALL CRTM_Clear_AtmScatter( AtmScatter ) ! Output
!
! OUTPUT ARGUMENTS:
!       AtmScatter:  CRTM_AtmScatter structure for which the scalar members have
!                    been cleared.
!                    UNITS:      N/A
!                    TYPE:       CRTM_AtmScatter_type
!                    DIMENSION:  Scalar
!                    ATTRIBUTES: INTENT(IN OUT)
!
! COMMENTS:
!       Note the INTENT on the output AtmScatter argument is IN OUT rather than
!       just OUT. This is necessary because the argument may be defined upon
!       input. To prevent memory leaks, the IN OUT INTENT is a must.
!
!----------------------------------------------------------------------------------

  SUBROUTINE CRTM_Clear_AtmScatter( AtmScatter )
    TYPE(CRTM_AtmScatter_type), INTENT(IN OUT) :: AtmScatter
    AtmScatter%n_Layers           = 0
    AtmScatter%Max_Legendre_Terms = 0
    AtmScatter%n_Legendre_Terms   = 0
    AtmScatter%Max_Phase_Elements = 0
    AtmScatter%n_Phase_Elements   = 0
    AtmScatter%lOffset = 0
  END SUBROUTINE CRTM_Clear_AtmScatter





!################################################################################
!################################################################################
!##                                                                            ##
!##                         ## PUBLIC MODULE ROUTINES ##                       ##
!##                                                                            ##
!################################################################################
!################################################################################

!--------------------------------------------------------------------------------
!
! NAME:
!       CRTM_Associated_AtmScatter
!
! PURPOSE:
!       Function to test the association status of the pointer members of a
!       CRTM_AtmScatter structure.
!
! CALLING SEQUENCE:
!       Association_Status = CRTM_Associated_AtmScatter( AtmScatter,         &  ! Input
!                                                        ANY_Test = Any_Test )  ! Optional input
!
! INPUT ARGUMENTS:
!       AtmScatter:          CRTM_AtmScatter structure which is to have its pointer
!                            member's association status tested.
!                            UNITS:      N/A
!                            TYPE:       CRTM_AtmScatter_type
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN)
!
! OPTIONAL INPUT ARGUMENTS:
!       ANY_Test:            Set this argument to test if ANY of the
!                            CRTM_AtmScatter structure pointer members are associated.
!                            The default is to test if ALL the pointer members
!                            are associated.
!                            If ANY_Test = 0, test if ALL the pointer members
!                                             are associated.  (DEFAULT)
!                               ANY_Test = 1, test if ANY of the pointer members
!                                             are associated.
!                            UNITS:      N/A
!                            TYPE:       INTEGER
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN), OPTIONAL
!
! FUNCTION RESULT:
!       Association_Status:  The return value is a logical value indicating the
!                            association status of the CRTM_AtmScatter pointer members.
!                            .TRUE.  - if ALL the CRTM_AtmScatter pointer members are
!                                      associated, or if the ANY_Test argument
!                                      is set and ANY of the CRTM_AtmScatter pointer
!                                      members are associated.
!                            .FALSE. - some or all of the CRTM_AtmScatter pointer
!                                      members are NOT associated.
!                            UNITS:      N/A
!                            TYPE:       LOGICAL
!                            DIMENSION:  Scalar
!
!--------------------------------------------------------------------------------

  FUNCTION CRTM_Associated_AtmScatter( AtmScatter, & ! Input
                                       ANY_Test )  & ! Optional input
                                     RESULT( Association_Status )
    ! Arguments
    TYPE(CRTM_AtmScatter_type), INTENT(IN) :: AtmScatter
    INTEGER,          OPTIONAL, INTENT(IN) :: ANY_Test
    ! Function result
    LOGICAL :: Association_Status
    ! Local variables
    LOGICAL :: ALL_Test


    ! ------
    ! Set up
    ! ------
    ! Default is to test ALL the pointer members
    ! for a true association status....
    ALL_Test = .TRUE.
    ! ...unless the ANY_Test argument is set.
    IF ( PRESENT( ANY_Test ) ) THEN
      IF ( ANY_Test == SET ) ALL_Test = .FALSE.
    END IF


    ! ---------------------------------------------
    ! Test the structure pointer member association
    ! ---------------------------------------------
    Association_Status = .FALSE.
    IF ( ALL_Test ) THEN
      IF ( ASSOCIATED( AtmScatter%Optical_Depth         ) .AND. &
           ASSOCIATED( AtmScatter%Single_Scatter_Albedo ) .AND. &
           ASSOCIATED( AtmScatter%Asymmetry_Factor      ) .AND. &
           ASSOCIATED( AtmScatter%Delta_Truncation      ) .AND. &
           ASSOCIATED( AtmScatter%Phase_Coefficient     )       ) THEN
        Association_Status = .TRUE.
      END IF
    ELSE
      IF ( ASSOCIATED( AtmScatter%Optical_Depth         ) .OR. &
           ASSOCIATED( AtmScatter%Single_Scatter_Albedo ) .OR. &
           ASSOCIATED( AtmScatter%Asymmetry_Factor      ) .OR. &
           ASSOCIATED( AtmScatter%Delta_Truncation      ) .OR. &
           ASSOCIATED( AtmScatter%Phase_Coefficient     )      ) THEN
        Association_Status = .TRUE.
      END IF
    END IF

  END FUNCTION CRTM_Associated_AtmScatter


!--------------------------------------------------------------------------------
!
! NAME:
!       CRTM_Destroy_AtmScatter
! 
! PURPOSE:
!       Function to re-initialize the scalar and pointer members of
!       a CRTM_AtmScatter data structure.
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Destroy_AtmScatter( AtmScatter,               &  ! Output
!                                               RCS_Id = RCS_Id,          &  ! Revision control
!                                               Message_Log = Message_Log )  ! Error messaging
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:  Character string specifying a filename in which any
!                     messages will be logged. If not specified, or if an
!                     error occurs opening the log file, the default action
!                     is to output messages to standard output.
!                     UNITS:      None
!                     TYPE:       CHARACTER(*)
!                     DIMENSION:  Scalar
!                     ATTRIBUTES: INTENT(IN), OPTIONAL
!
! OUTPUT ARGUMENTS:
!       AtmScatter:   Re-initialized CRTM_AtmScatter structure.
!                     UNITS:      N/A
!                     TYPE:       CRTM_AtmScatter_type
!                     DIMENSION:  Scalar OR Rank-1 array
!                     ATTRIBUTES: INTENT(IN OUT)
!
! OPTIONAL OUTPUT ARGUMENTS:
!       RCS_Id:       Character string containing the Revision Control
!                     System Id field for the module.
!                     UNITS:      None
!                     TYPE:       CHARACTER(*)
!                     DIMENSION:  Scalar
!                     ATTRIBUTES: INTENT(OUT), OPTIONAL
!
! FUNCTION RESULT:
!       Error_Status: The return value is an integer defining the error status.
!                     The error codes are defined in the Message_Handler module.
!                     If == SUCCESS the structure re-initialisation was successful
!                        == FAILURE - an error occurred, or
!                                   - the structure internal allocation counter
!                                     is not equal to zero (0) upon exiting this
!                                     function. This value is incremented and
!                                     decremented for every structure allocation
!                                     and deallocation respectively.
!                     UNITS:      N/A
!                     TYPE:       INTEGER
!                     DIMENSION:  Scalar
!
! COMMENTS:
!       Note the INTENT on the output AtmScatter argument is IN OUT rather than
!       just OUT. This is necessary because the argument may be defined upon
!       input. To prevent memory leaks, the IN OUT INTENT is a must.
!
!--------------------------------------------------------------------------------

  FUNCTION CRTM_Destroy_AtmScatter( AtmScatter,   &  ! Output
                                    No_Clear,     &  ! Optional input
                                    RCS_Id,       &  ! Revision control
                                    Message_Log ) &  ! Error messaging
                                  RESULT( Error_Status )
    ! Arguments
    TYPE(CRTM_AtmScatter_type), INTENT(IN OUT) :: AtmScatter
    INTEGER,          OPTIONAL, INTENT(IN)     :: No_Clear
    CHARACTER(*),     OPTIONAL, INTENT(OUT)    :: RCS_Id
    CHARACTER(*),     OPTIONAL, INTENT(IN)     :: Message_Log
    ! Function result
    INTEGER :: Error_Status
    ! Local parameters
    CHARACTER(*), PARAMETER :: ROUTINE_NAME = 'CRTM_Destroy_AtmScatter'
    ! Local variables
    CHARACTER( 256 ) :: Message
    LOGICAL :: Clear
    INTEGER :: Allocate_Status


    ! ------
    ! Set up
    ! ------
    Error_Status = SUCCESS
    IF ( PRESENT( RCS_Id ) ) RCS_Id = MODULE_RCS_ID

    ! Default is to clear scalar members...
    Clear = .TRUE.
    ! ....unless the No_Clear argument is set
    IF ( PRESENT( No_Clear ) ) THEN
      IF ( No_Clear == SET ) Clear = .FALSE.
    END IF


    ! -----------------------------
    ! Initialise the scalar members
    ! -----------------------------
    IF ( Clear ) CALL CRTM_Clear_AtmScatter( AtmScatter )


    ! -----------------------------------------------------
    ! If ALL pointer members are NOT associated, do nothing
    ! -----------------------------------------------------
    IF ( .NOT. CRTM_Associated_AtmScatter( AtmScatter ) ) RETURN


    ! ------------------------------
    ! Deallocate the pointer members
    ! ------------------------------
    ! Deallocate the CRTM_AtmScatter Phase_Coefficient
    IF ( ASSOCIATED( AtmScatter%Phase_Coefficient ) ) THEN
      DEALLOCATE( AtmScatter%Phase_Coefficient, STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
        Error_Status = FAILURE
        WRITE( Message, '( "Error deallocating CRTM_AtmScatter Phase_Coefficient ", &
                          &"member. STAT = ", i5 )' ) &
                        Allocate_Status
        CALL Display_Message( ROUTINE_NAME,    &
                              TRIM( Message ), &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
    END IF

    ! Deallocate the CRTM_AtmScatter Optical_Depth
    IF ( ASSOCIATED( AtmScatter%Optical_Depth ) ) THEN
      DEALLOCATE( AtmScatter%Optical_Depth, STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
        Error_Status = FAILURE
        WRITE( Message, '( "Error deallocating CRTM_AtmScatter Optical_Depth ", &
                          &"member. STAT = ", i5 )' ) &
                        Allocate_Status
        CALL Display_Message( ROUTINE_NAME,    &
                              TRIM( Message ), &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
    END IF

    ! Deallocate the CRTM_AtmScatter Single_Scatter_Albedo
    IF ( ASSOCIATED( AtmScatter%Single_Scatter_Albedo ) ) THEN
      DEALLOCATE( AtmScatter%Single_Scatter_Albedo, STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
        Error_Status = FAILURE
        WRITE( Message, '( "Error deallocating CRTM_AtmScatter Single_Scatter_Albedo ", &
                          &"member. STAT = ", i5 )' ) &
                        Allocate_Status
        CALL Display_Message( ROUTINE_NAME,    &
                              TRIM( Message ), &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
    END IF

    ! Deallocate the CRTM_AtmScatter Asymmetry_Factor
    IF ( ASSOCIATED( AtmScatter%Asymmetry_Factor ) ) THEN
      DEALLOCATE( AtmScatter%Asymmetry_Factor, STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
        Error_Status = FAILURE
        WRITE( Message, '( "Error deallocating CRTM_AtmScatter Asymmetry_Factor ", &
                          &"member. STAT = ", i5 )' ) &
                        Allocate_Status
        CALL Display_Message( ROUTINE_NAME,    &
                              TRIM( Message ), &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
    END IF

    ! Deallocate the CRTM_AtmScatter Delta_Truncation
    IF ( ASSOCIATED( AtmScatter%Delta_Truncation ) ) THEN
      DEALLOCATE( AtmScatter%Delta_Truncation, STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
        Error_Status = FAILURE
        WRITE( Message, '( "Error deallocating CRTM_AtmScatter Delta_Truncation ", &
                          &"member. STAT = ", i5 )' ) &
                        Allocate_Status
        CALL Display_Message( ROUTINE_NAME,    &
                              TRIM( Message ), &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
    END IF


    ! -------------------------------------
    ! Decrement and test allocation counter
    ! -------------------------------------
    AtmScatter%n_Allocates = AtmScatter%n_Allocates - 1
    IF ( AtmScatter%n_Allocates /= 0 ) THEN
      Error_Status = FAILURE
      WRITE( Message, '( "Allocation counter /= 0, Value = ", i5 )' ) &
                      AtmScatter%n_Allocates
      CALL Display_Message( ROUTINE_NAME,    &
                            TRIM( Message ), &
                            Error_Status,    &
                            Message_Log = Message_Log )
    END IF

  END FUNCTION CRTM_Destroy_AtmScatter


!--------------------------------------------------------------------------------
!
! NAME:
!       CRTM_Allocate_AtmScatter
! 
! PURPOSE:
!       Function to allocate the pointer members of the CRTM_AtmScatter
!       data structure.
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Allocate_AtmScatter( n_Layers,                 &  ! Input
!                                                n_Legendre_Terms,         &  ! Input
!                                                n_Phase_Elements,         &  ! Input
!                                                AtmScatter,               &  ! Output
!                                                RCS_Id = RCS_Id,          &  ! Revision control
!                                                Message_Log = Message_Log )  ! Error messaging
!
! INPUT ARGUMENTS:
!         n_Layers:          Number of atmospheric layers dimension.
!                            Must be > 0
!                            UNITS:      N/A
!                            TYPE:       INTEGER
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN)
!
!         n_Legendre_Terms:  The number of Legendre polynomial terms dimension.
!                            Must be > 0
!                            UNITS:      N/A
!                            TYPE:       INTEGER
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN)
!
!         n_Phase_Elements:  The number of phase elements dimension.
!                            Must be > 0
!                            UNITS:      N/A
!                            TYPE:       INTEGER
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN)
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:         Character string specifying a filename in which any
!                            messages will be logged. If not specified, or if an
!                            error occurs opening the log file, the default action
!                            is to output messages to standard output.
!                            UNITS:      None
!                            TYPE:       CHARACTER(*)
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN), OPTIONAL
!
! OUTPUT ARGUMENTS:
!       AtmScatter:          CRTM_AtmScatter structure with allocated pointer members
!                            UNITS:      N/A
!                            TYPE:       CRTM_AtmScatter_type
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(IN OUT)
!
!
! OPTIONAL OUTPUT ARGUMENTS:
!       RCS_Id:              Character string containing the Revision Control
!                            System Id field for the module.
!                            UNITS:      None
!                            TYPE:       CHARACTER(*)
!                            DIMENSION:  Scalar
!                            ATTRIBUTES: INTENT(OUT), OPTIONAL
!
! FUNCTION RESULT:
!       Error_Status:        The return value is an integer defining the error status.
!                            The error codes are defined in the Message_Handler module.
!                            If == SUCCESS the structure re-initialisation was successful
!                               == FAILURE - an error occurred, or
!                                          - the structure internal allocation counter
!                                            is not equal to one (1) upon exiting this
!                                            function. This value is incremented and
!                                            decremented for every structure allocation
!                                            and deallocation respectively.
!                            UNITS:      N/A
!                            TYPE:       INTEGER
!                            DIMENSION:  Scalar
!
! COMMENTS:
!       Note the INTENT on the output AtmScatter argument is IN OUT rather than
!       just OUT. This is necessary because the argument may be defined upon
!       input. To prevent memory leaks, the IN OUT INTENT is a must.
!
!--------------------------------------------------------------------------------

  FUNCTION CRTM_Allocate_AtmScatter( n_Layers,         &  ! Input
                                     n_Legendre_Terms, &  ! Input
                                     n_Phase_Elements, &  ! Input
                                     AtmScatter,       &  ! Output
                                     RCS_Id,           &  ! Revision control
                                     Message_Log )     &  ! Error messaging
                                   RESULT( Error_Status )
    ! Arguments
    INTEGER,                    INTENT(IN)     :: n_Layers         
    INTEGER,                    INTENT(IN)     :: n_Legendre_Terms 
    INTEGER,                    INTENT(IN)     :: n_Phase_Elements 
    TYPE(CRTM_AtmScatter_type), INTENT(IN OUT) :: AtmScatter
    CHARACTER(*),     OPTIONAL, INTENT(OUT)    :: RCS_Id
    CHARACTER(*),     OPTIONAL, INTENT(IN)     :: Message_Log
    ! Function result
    INTEGER :: Error_Status
    ! Local parameters
    CHARACTER(*), PARAMETER :: ROUTINE_NAME = 'CRTM_Allocate_AtmScatter'
    ! Local variables
    CHARACTER( 256 ) :: Message
    INTEGER :: Allocate_Status


    ! ------
    ! Set up
    ! ------
    Error_Status = SUCCESS
    IF ( PRESENT( RCS_Id ) ) RCS_Id = MODULE_RCS_ID

    ! Dimensions
    IF ( n_Layers < 1 ) THEN
      Error_Status = FAILURE
      CALL Display_Message( ROUTINE_NAME, &
                            'Input n_Layers must be > 0.', &
                            Error_Status, &
                            Message_Log = Message_Log )
      RETURN
    END IF

    IF ( n_Legendre_Terms < 1 ) THEN
      Error_Status = FAILURE
      CALL Display_Message( ROUTINE_NAME, &
                            'Input n_Legendre_Terms must be > 0.', &
                            Error_Status, &
                            Message_Log = Message_Log )
      RETURN
    END IF

    IF ( n_Phase_Elements < 1 ) THEN
      Error_Status = FAILURE
      CALL Display_Message( ROUTINE_NAME, &
                            'Input n_Phase_Elements must be > 0.', &
                            Error_Status, &
                            Message_Log = Message_Log )
      RETURN
    END IF

    ! Check if ANY pointers are already associated
    ! If they are, deallocate them but leave scalars.
    IF ( CRTM_Associated_AtmScatter( AtmScatter, ANY_Test = SET ) ) THEN
      Error_Status = CRTM_Destroy_AtmScatter( AtmScatter, &
                                              No_Clear = SET, &
                                              Message_Log = Message_Log )
      IF ( Error_Status /= SUCCESS ) THEN
        CALL Display_Message( ROUTINE_NAME,    &
                              'Error deallocating CRTM_AtmScatter pointer members.', &
                              Error_Status,    &
                              Message_Log = Message_Log )
        RETURN
      END IF
    END IF


    ! ----------------------
    ! Perform the allocation
    ! ----------------------
    ALLOCATE( &
              ! MANDATORY structure members
              AtmScatter%Optical_Depth( n_Layers ),         &
              AtmScatter%Single_Scatter_Albedo( n_Layers ), &
              AtmScatter%Asymmetry_Factor( n_Layers ),      &
              AtmScatter%Delta_Truncation( n_Layers ),      &
              ! ALGORITHM-SPECIFIC structure members
              AtmScatter%Phase_Coefficient( 0:n_Legendre_Terms, &
                                              n_Phase_Elements, &
                                              n_Layers  ), &
              STAT = Allocate_Status )
    IF ( Allocate_Status /= 0 ) THEN
      Error_Status = FAILURE
      WRITE( Message, '( "Error allocating AtmScatter data arrays. STAT = ", i5 )' ) &
                      Allocate_Status
      CALL Display_Message( ROUTINE_NAME,    &
                            TRIM( Message ), &
                            Error_Status,    &
                            Message_Log = Message_Log )
      RETURN
    END IF


    ! ------------------------------------------
    ! Assign the dimensions and initalise arrays
    ! ------------------------------------------
    AtmScatter%n_Layers           = n_Layers
    AtmScatter%Max_Legendre_Terms = n_Legendre_Terms
    AtmScatter%n_Legendre_Terms   = n_Legendre_Terms
    AtmScatter%Max_Phase_Elements = n_Phase_Elements
    AtmScatter%n_Phase_Elements   = n_Phase_Elements
    ! MANDATORY structure members
    AtmScatter%Optical_Depth         = ZERO
    AtmScatter%Single_Scatter_Albedo = ZERO
    AtmScatter%Asymmetry_Factor      = ZERO
    AtmScatter%Delta_Truncation      = ZERO
    ! ALGORITHM-SPECIFIC structure members
    AtmScatter%Phase_Coefficient     = ZERO


    ! -------------------------------------
    ! Increment and test allocation counter
    ! -------------------------------------
    AtmScatter%n_Allocates = AtmScatter%n_Allocates + 1
    IF ( AtmScatter%n_Allocates /= 1 ) THEN
      Error_Status = FAILURE
      WRITE( Message, '( "Allocation counter /= 1, Value = ", i5 )' ) &
                      AtmScatter%n_Allocates
      CALL Display_Message( ROUTINE_NAME,    &
                            TRIM( Message ), &
                            Error_Status,    &
                            Message_Log = Message_Log )
    END IF

  END FUNCTION CRTM_Allocate_AtmScatter


!--------------------------------------------------------------------------------
!
! NAME:
!       CRTM_Assign_AtmScatter
!
! PURPOSE:
!       Function to copy valid CRTM_AtmScatter structures.
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Assign_AtmScatter( AtmScatter_in,            &  ! Input
!                                              AtmScatter_out,           &  ! Output
!                                              RCS_Id = RCS_Id,          &  ! Revision control
!                                              Message_Log = Message_Log )  ! Error messaging
!
! INPUT ARGUMENTS:
!       AtmScatter_in:   CRTM_AtmScatter structure which is to be copied.
!                        UNITS:      N/A
!                        TYPE:       CRTM_AtmScatter_type
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT(IN)
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:     Character string specifying a filename in which any
!                        messages will be logged. If not specified, or if an
!                        error occurs opening the log file, the default action
!                        is to output messages to standard output.
!                        UNITS:      None
!                        TYPE:       CHARACTER(*)
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT(IN), OPTIONAL
!
! OUTPUT ARGUMENTS:
!       AtmScatter_out:  Copy of the input structure, CRTM_AtmScatter_in.
!                        UNITS:      N/A
!                        TYPE:       CRTM_AtmScatter_type
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT(IN OUT)
!
!
! OPTIONAL OUTPUT ARGUMENTS:
!       RCS_Id:          Character string containing the Revision Control
!                        System Id field for the module.
!                        UNITS:      None
!                        TYPE:       CHARACTER(*)
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT(OUT), OPTIONAL
!
! FUNCTION RESULT:
!       Error_Status:    The return value is an integer defining the error status.
!                        The error codes are defined in the Message_Handler module.
!                        If == SUCCESS the structure assignment was successful
!                           == FAILURE an error occurred
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Scalar
!
! COMMENTS:
!       Note the INTENT on the output AtmScatter argument is IN OUT rather than
!       just OUT. This is necessary because the argument may be defined upon
!       input. To prevent memory leaks, the IN OUT INTENT is a must.
!
!--------------------------------------------------------------------------------

  FUNCTION CRTM_Assign_AtmScatter( AtmScatter_in,  &  ! Input
                                   AtmScatter_out, &  ! Output
                                   RCS_Id,         &  ! Revision control
                                   Message_Log )   &  ! Error messaging
                                 RESULT( Error_Status )
    ! Arguments
    TYPE(CRTM_AtmScatter_type), INTENT(IN)     :: AtmScatter_in
    TYPE(CRTM_AtmScatter_type), INTENT(IN OUT) :: AtmScatter_out
    CHARACTER(*),     OPTIONAL, INTENT(OUT)    :: RCS_Id
    CHARACTER(*),     OPTIONAL, INTENT(IN)     :: Message_Log
    ! Function result
    INTEGER :: Error_Status
    ! Local parameters
    CHARACTER(*), PARAMETER :: ROUTINE_NAME = 'CRTM_Assign_AtmScatter'


    ! ------
    ! Set up
    ! ------
    Error_Status = SUCCESS
    IF ( PRESENT( RCS_Id ) ) RCS_Id = MODULE_RCS_ID

    ! ALL *input* pointers must be associated.
    ! If this test succeeds, then some or all of the
    ! input pointers are NOT associated, so destroy
    ! the output structure and return.
    IF ( .NOT. CRTM_Associated_AtmScatter( AtmScatter_In ) ) THEN
      Error_Status = CRTM_Destroy_AtmScatter( AtmScatter_Out, &
                                              Message_Log = Message_Log )
      IF ( Error_Status /= SUCCESS ) THEN
        CALL Display_Message( ROUTINE_NAME,    &
                              'Error deallocating output CRTM_AtmScatter pointer members.', &
                              Error_Status,    &
                              Message_Log = Message_Log )
      END IF
      RETURN
    END IF


    ! ----------------------
    ! Allocate the structure
    ! ----------------------
    Error_Status = CRTM_Allocate_AtmScatter( AtmScatter_in%n_Layers, &
                                             AtmScatter_in%Max_Legendre_Terms, &
                                             AtmScatter_in%Max_Phase_Elements, &
                                             AtmScatter_out, &
                                             Message_Log = Message_Log )
    IF ( Error_Status /= SUCCESS ) THEN
      CALL Display_Message( ROUTINE_NAME, &
                            'Error allocating output AtmScatter arrays.', &
                            Error_Status, &
                            Message_Log = Message_Log )
      RETURN
    END IF


    ! ---------------------
    ! Assign scalar members
    ! ---------------------
    AtmScatter_out%n_Legendre_Terms = AtmScatter_in%n_Legendre_Terms
    AtmScatter_out%n_Phase_Elements = AtmScatter_in%n_Phase_Elements
    AtmScatter_out%lOffset = AtmScatter_in%lOffset


    ! -----------------
    ! Assign array data
    ! -----------------
    ! MANDATORY structure members
    AtmScatter_out%Optical_Depth         = AtmScatter_in%Optical_Depth
    AtmScatter_out%Single_Scatter_Albedo = AtmScatter_in%Single_Scatter_Albedo 
    AtmScatter_out%Asymmetry_Factor      = AtmScatter_in%Asymmetry_Factor      
    AtmScatter_out%Delta_Truncation      = AtmScatter_in%Delta_Truncation     
    ! ALGORITHM-SPECIFIC structure members
    AtmScatter_out%Phase_Coefficient     = AtmScatter_in%Phase_Coefficient     

  END FUNCTION CRTM_Assign_AtmScatter

END MODULE CRTM_AtmScatter_Define
