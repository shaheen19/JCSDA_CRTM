!
! LBLRTM_r7p2_Module
!
! Module containing procedures for LBLRTM Record r7p2.
!
!
! CREATION HISTORY:
!       Written by:   Paul van Delst, 18-Dec-2012
!                     paul.vandelst@noaa.gov
!

MODULE LBLRTM_r7p2_Module

  ! -----------------
  ! Environment setup
  ! -----------------
  ! Module usage
  USE Type_Kinds     , ONLY: fp
  USE File_Utility   , ONLY: File_Open
  USE Message_Handler, ONLY: SUCCESS, FAILURE, INFORMATION, Display_Message
  ! Line-by-line model parameters
  USE LBL_Parameters
  ! Disable implicit typing
  IMPLICIT NONE


  ! ----------
  ! Visibility
  ! ----------
  ! Everything private by default
  PRIVATE
  ! Datatypes
  PUBLIC :: LBLRTM_r7p2_type
  ! Procedures
  PUBLIC :: LBLRTM_r7p2_Write


  ! -----------------
  ! Module parameters
  ! -----------------
  CHARACTER(*), PARAMETER :: MODULE_VERSION_ID = &
  '$Id$'
  ! Message string length
  INTEGER, PARAMETER :: ML = 256
  ! The record I/O format
  CHARACTER(*), PARAMETER :: LBLRTM_R7P2_FMT = '(a)'


  ! -------------
  ! Derived types
  ! -------------
  TYPE :: LBLRTM_r7p2_type
    CHARACTER(80) :: ivar = '(es13.6)'  !  Format specification for reading filter values
  END TYPE LBLRTM_r7p2_type


CONTAINS


  FUNCTION LBLRTM_r7p2_Write(r7p2,fid) RESULT(err_stat)

    ! Arguments
    TYPE(LBLRTM_r7p2_type), INTENT(IN) :: r7p2
    INTEGER               , INTENT(IN) :: fid
    ! Function result
    INTEGER :: err_stat
    ! Function parameters
    CHARACTER(*), PARAMETER :: ROUTINE_NAME = 'LBLRTM_r7p2_Write'
    ! Function variables
    CHARACTER(ML) :: msg
    INTEGER :: io_stat

    ! Setup
    err_stat = SUCCESS
    ! ...Check unit is open
    IF ( .NOT. File_Open(fid) ) THEN
      msg = 'File unit is not connected'
      CALL Cleanup(); RETURN
    END IF

    ! Write the record
    WRITE( fid,FMT=LBLRTM_R7P2_FMT,IOSTAT=io_stat) r7p2
    IF ( io_stat /= 0 ) THEN
      WRITE( msg,'("Error writing record. IOSTAT = ",i0)' ) io_stat
      CALL Cleanup(); RETURN
    END IF

  CONTAINS

    SUBROUTINE CleanUp()
      err_stat = FAILURE
      CALL Display_Message( ROUTINE_NAME,msg,err_stat )
    END SUBROUTINE CleanUp

  END FUNCTION LBLRTM_r7p2_Write

END MODULE LBLRTM_r7p2_Module