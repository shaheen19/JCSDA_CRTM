!------------------------------------------------------------------------------
! NAME:
!       Create_ProcessControl_File
!
! PURPOSE:
!       Program to create a generic Process Control file (profile and molecule
!       set independent) for the transmittance production software given an
!       input list of netCDF SRF data files.
!
! CATEGORY:
!       Transmittance Production
!
! LANGUAGE:
!       Fortran-95
!
! MODULES:
!       Type_Kinds:                Module containing definitions for kinds
!                                  of variable types.
!
!       File_Utility:              Module containing generic file utility routines
!
!       Message_Handler:             Module to define simple error codes and
!                                  handle error conditions
!                                  USEs: FILE_UTILITY module
!
!       SensorInfo_Define:         Module defining the SensorInfo data
!                                  structure and containing routines to
!                                  manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!
!       SensorInfo_LinkedList:     Module defining the SensorInfo Linked
!                                  List data structure and containing
!                                  routines to manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!                                        SENSORINFO_DEFINE module
!
!       SensorInfo_IO:             Module continaing routines to read and
!                                  write ASCII SensorInfo format files.
!                                  USEs: TYPE_KINDS module
!                                        FILE_UTILITY module
!                                        ERROR_HANDLER module
!                                        SENSORINFO_DEFINE module
!
!       SRF_Define:                Module defining the SRF data structure and
!                                  containing routines to manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!
!       SRF_netCDF_IO:             Module containing routines to read and write
!                                  netCDF SRF format files.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!                                        SRF_DEFINE module
!                                        NETCDF module
!                                        NETCDF_UTILITY module
!
!       ProcessControl_Define:     Module containing the ProcessControl
!                                  data type definition and routines to
!                                  manipulate the structure.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!
!       ProcessControl_IO:         Module containing routines to read and write
!                                  ASCII Process Control files.
!                                  USEs: TYPE_KINDS module
!                                        FILE_UTILITY module
!                                        ERROR_HANDLER module
!                                        PROCESSCONTROL_DEFINE module
!
!       Tau_Production_Parameters: Module defining parameters used in the LBL
!                                  transmittance production runs
!                                  USEs: TYPE_KINDS module
!                                        LBLRTM_PARAMETERS module
!
!       Tau_Production_Utility:    Module continaing utility routines for the LBL
!                                  transmittance production runs.
!                                  USEs: TYPE_KINDS module
!                                        FILE_UTILITY module
!                                        ERROR_HANDLER module
!                                        COMPARE_FLOAT_NUMBERS module
!                                        TRANSMITTANCE_PRODUCTION_PARAMETERS module
!
! CONTAINS:
!       None.
!
! INCLUDE FILES:
!       None.
!
! EXTERNALS:
!       None.
!
! COMMON BLOCKS:
!       None.
!
! FILES ACCESSED:
!       Input:  - SensorInfo file.
!               - netCDF format SRF data file(s).
!
!       Output: ASCII ProcessControl file.
!
! SIDE EFFECTS:
!       If the ProcessControl file already exists, it is overwritten.
!
! RESTRICTIONS:
!       The maximum number of input SRF files that can be processed
!       is limited to 100.
!
! CREATION HISTORY:
!       Written by:     Paul van Delst, CIMSS/SSEC 26-Apr-2002
!                       paul.vandelst@ssec.wisc.edu
!
!  Copyright (C) 2002 Paul van Delst
!
!  This program is free software; you can redistribute it and/or
!  modify it under the terms of the GNU General Public License
!  as published by the Free Software Foundation; either version 2
!  of the License, or (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with this program; if not, write to the Free Software
!  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
!
!------------------------------------------------------------------------------

PROGRAM Create_ProcessControl_File


  ! ------------
  ! Module usage
  ! ------------

  USE Type_Kinds
  USE File_Utility
  USE Message_Handler

  USE SensorInfo_Define
  USE SensorInfo_LinkedList
  USE SensorInfo_IO

  USE SRF_Define
  USE SRF_netCDF_IO

  USE ProcessControl_Define
  USE ProcessControl_IO

  USE Tau_Production_Parameters
  USE Tau_Production_Utility


  ! -----------------------
  ! Disable implicit typing
  ! -----------------------

  IMPLICIT NONE


  ! ----------
  ! Parameters
  ! ----------

  CHARACTER( * ), PARAMETER :: PROGRAM_NAME = 'Create_ProcessControl_File'
  CHARACTER( * ), PARAMETER :: PROGRAM_RCS_ID = &
  '$Id: Create_ProcessControl_File.f90,v 2.3 2006/06/30 16:47:16 dgroff Exp $'
  CHARACTER( * ), PARAMETER :: PROGRAM_HEADER = &
  '**********************************************************'

  ! -- Maximum number of sensors to allow
  INTEGER, PARAMETER :: MAX_N_SENSORS = 100

  ! -- Integer keyword set
  INTEGER, PARAMETER :: SET = 1


  ! ---------
  ! Variables
  ! ---------

  CHARACTER( 256 ) :: Message

  INTEGER         :: pn_pos
  CHARACTER( 80 ) :: pn_fmt

  CHARACTER( 512 ) :: SensorInfo_Filename
  CHARACTER( 512 ) :: SRF_FilePath
  CHARACTER( 512 ) :: SRF_Filename
  CHARACTER( 512 ) :: ProcessControl_Filename

  INTEGER :: IO_Status
  INTEGER :: Error_Status
  INTEGER :: Allocate_Status

  INTEGER,          DIMENSION( MAX_N_SENSORS ) :: Available_Sensor
  CHARACTER( 512 ), DIMENSION( MAX_N_SENSORS ) :: Available_SRF_Filename

  INTEGER :: i, l, ch

  INTEGER :: n_Available_Sensors
  INTEGER :: n_Channels
  INTEGER :: Valid_Channel

  INTEGER,         DIMENSION( : ), ALLOCATABLE :: n_SRF_Frequencies
  REAL( fp_kind ), DIMENSION( : ), ALLOCATABLE :: Begin_SRF_Frequency
  REAL( fp_kind ), DIMENSION( : ), ALLOCATABLE :: End_SRF_Frequency

  REAL( fp_kind ) :: dF
  INTEGER         :: Idx, dF_Index

  INTEGER :: n_Sensors, n
  TYPE( SensorInfo_type )      :: SensorInfo
  TYPE( SensorInfo_List_type ) :: SensorInfo_List

  TYPE( ProcessControl_type ) :: ProcessControl



  !#----------------------------------------------------------------------------#
  !#                   -- CREATE THE SensorInfo LINKED LIST --                  #
  !#----------------------------------------------------------------------------#

  SensorInfo_List = New_SensorInfo_List()



  !#----------------------------------------------------------------------------#
  !#                       -- OUTPUT DESCRIPTIVE HEADER --                      #
  !#----------------------------------------------------------------------------#

  pn_pos = ( LEN( PROGRAM_HEADER ) / 2 ) - &
           ( LEN( PROGRAM_NAME ) / 2 )
  pn_pos = MAX( pn_pos, 0 ) + 5
  WRITE( pn_fmt, '( "( ",i2,"x, a )" )' ) pn_pos

  WRITE( *, '(/5x, a )' ) PROGRAM_HEADER
  WRITE( *, FMT = TRIM( pn_fmt ) ) PROGRAM_NAME
  WRITE( *, '(/5x, " Program to create a transmittance production Process")' )
  WRITE( *, '( 5x, "   Control file from netCDF format SRF files.")' )
  WRITE( *, '(/5x, " $Revision: 2.3 $")' )
  WRITE( *, '( 5x, a, / )' ) PROGRAM_HEADER



  !#----------------------------------------------------------------------------#
  !#                       -- READ THE SensorInfo FILE --                       #
  !#----------------------------------------------------------------------------#

  ! ---------------------------
  ! Get the SensorInfo filename
  ! ---------------------------

  WRITE( *, FMT     = '( /5x, "Enter a SensorInfo filename: " )', &
            ADVANCE = 'NO' )
  READ( *, FMT = '( a )' ) SensorInfo_Filename
  SensorInfo_Filename = ADJUSTL( SensorInfo_Filename )


  ! ------------------------
  ! Read the SensorInfo file
  ! ------------------------

  Error_Status = Read_SensorInfo( SensorInfo_Filename, &
                                  SensorInfo_List, &
                                  Quiet = SET )
                               
  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error reading SensorInfo file '//&
                          TRIM( SensorInfo_Filename ), &
                          FAILURE )
    STOP
  END IF

  ! -- Count the number of sensors
  n_Sensors = Count_SensorInfo_Nodes( SensorInfo_List )

  IF ( n_Sensors < 1 ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'SensorInfo_List is empty.', &
                          FAILURE )
    STOP
  END IF



  !#----------------------------------------------------------------------------#
  !#                       -- GET SRF DATA FILE PATH --                         #
  !#----------------------------------------------------------------------------#

  WRITE( *, FMT     = '( /5x, "Enter the SRF data file path [e.g. ./SRF_Data/]: " )', &
            ADVANCE = 'NO' )
  READ( *, FMT = '( a )' ) SRF_FilePath

  SRF_FilePath = ADJUSTL( SRF_FilePath )



  !#----------------------------------------------------------------------------#
  !#             -- LOOP OVER SENSORS TO COUNT THE TOTAL NUMBER --              #
  !#             --     OF AVAILABLE SENSORS AND CHANNELS       --              #
  !#----------------------------------------------------------------------------#

  ! ----------------------------------------------------
  ! Initialise the available sensor and channel counters
  ! ----------------------------------------------------

  n_Available_Sensors = 0
  n_Channels          = 0


  ! -----------------
  ! Begin sensor loop
  ! -----------------
  
  Sensor_Count_Loop: DO n = 1, n_Sensors


    ! ---------------------------------------------
    ! Get the current SensorInfo data from the list
    ! ---------------------------------------------

    Error_Status = GetFrom_SensorInfo_List( SensorInfo_List, &
                                            n, &
                                            SensorInfo )

    IF ( Error_Status /= SUCCESS ) THEN
      Error_Status = FAILURE
      WRITE( Message, '( "Error retrieving SensorInfo data for sensor # ", i5, &
                        &" in count loop." )' ) n
      CALL Display_Message( PROGRAM_NAME, &
                            TRIM( Message ), &
                            Error_Status )
      STOP
    END IF


    ! --------------------------
    ! Construct the SRF filename
    ! --------------------------

    SRF_Filename = TRIM( SRF_FilePath )//TRIM( SensorInfo%Sensor_Id )//'.srf.nc'



    !#--------------------------------------------------------------------------#
    !#                   -- ONLY INCLUDE FILES THAT EXIST --                    #
    !#--------------------------------------------------------------------------#

    Count_Available_Sensors: IF ( File_Exists( TRIM( SRF_Filename ) ) ) THEN


      ! -----------------------------------------
      ! Increment the number of available sensors
      ! -----------------------------------------

      n_Available_Sensors = n_Available_Sensors + 1

      IF ( n_Available_Sensors > MAX_N_SENSORS ) THEN
        WRITE( Message, '( "Maximum number of sensors, ", i3, ", exceeded." )' ) MAX_N_SENSORS
        CALL Display_Message( PROGRAM_NAME, &
                              TRIM( Message ), &
                              FAILURE )
        STOP
      END IF


      ! --------------------------------
      ! Increment the number of channels
      ! --------------------------------

      n_Channels = n_Channels + SensorInfo%n_Channels


      ! -------------------------------
      ! Save the SensorInfo node number
      ! and SRF filename of this sensor
      ! -------------------------------

      Available_Sensor( n_Available_Sensors ) = n
      Available_SRF_Filename( n_Available_Sensors ) = TRIM( SRF_Filename )
      

    END IF Count_Available_Sensors



    !#--------------------------------------------------------------------------#
    !#              -- DESTROY THE CURRENT SensorInfo STRUCTURE --              #
    !#--------------------------------------------------------------------------#

    Error_Status = Destroy_SensorInfo( SensorInfo )

    IF ( Error_Status /= SUCCESS ) THEN
      WRITE( Message, '( "Error destroying SensorInfo for sensor # ", i5, &
                        &" in count loop." )' ) n
      CALL Display_Message( PROGRAM_NAME, &
                            TRIM( Message ), &
                            Error_Status )
      STOP
    END IF

  END DO Sensor_Count_Loop



  !#----------------------------------------------------------------------------#
  !#                      -- CHECK THAT WE HAVE SOMETHING --                    #
  !#----------------------------------------------------------------------------#

  IF ( n_Available_Sensors < 1 .OR. n_Channels < 1 ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'No available sensors of channels!', &
                          FAILURE )
    STOP
  END IF



  !#----------------------------------------------------------------------------#
  !#                -- ALLOCATE THE ProcessControl STRUCTURE --                 #
  !#----------------------------------------------------------------------------#

  Error_Status = Allocate_ProcessControl( n_Available_Sensors, &
                                          n_Channels, &
                                          ProcessControl )

  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error allocating ProcessControl structure.', &
                          FAILURE )
    STOP
  END IF



  !#----------------------------------------------------------------------------#
  !#              -- LOOP OVER AVAILABLE SENSORS TO READ DATA --                #
  !#              --  AND FILL THE ProcessControl STRUCTURE   --                #
  !#----------------------------------------------------------------------------#

  ! -------------------------------------
  ! Initialise main channel counter index
  ! -------------------------------------

  l = 0


  ! -----------------
  ! Begin sensor loop
  ! -----------------
  
  Sensor_Read_Loop: DO n = 1, n_Available_Sensors


    ! ----------------------------------------------
    ! Get the required SensorInfo data from the list
    ! ----------------------------------------------

    Error_Status = GetFrom_SensorInfo_List( SensorInfo_List, &
                                            Available_Sensor(n), &
                                            SensorInfo )

    IF ( Error_Status /= SUCCESS ) THEN
      Error_Status = FAILURE
      WRITE( Message, '( "Error retrieving SensorInfo data for sensor # ", i5, &
                        &" in read loop." )' ) Available_Sensor(n)
      CALL Display_Message( PROGRAM_NAME, &
                            TRIM( Message ), &
                            Error_Status )
      STOP
    END IF


    ! ---------------------------------
    ! Allocate the SRF frequency arrays
    ! ---------------------------------

    ALLOCATE( n_SRF_Frequencies(   SensorInfo%n_Channels ), &
              Begin_SRF_Frequency( SensorInfo%n_Channels ), &
              End_SRF_Frequency(   SensorInfo%n_Channels ), &
              STAT = Allocate_Status )

    IF ( Allocate_Status /= 0 ) THEN
      CALL Display_Message( PROGRAM_NAME, &
                            'Error allocating frequency arrays for SRF netCDF file '//&
                            TRIM( Available_SRF_Filename(n) )//' read.', &
                            FAILURE )
      STOP
    END IF


    ! -----------------------
    ! Read the frequency data
    ! -----------------------

    Error_Status = Inquire_SRF_netCDF( TRIM( Available_SRF_Filename(n) ), &
                                       n_Points        = n_SRF_Frequencies, &
                                       Begin_Frequency = Begin_SRF_Frequency, &
                                       End_Frequency   = End_SRF_Frequency    )

    IF ( Error_Status /= SUCCESS ) THEN
      CALL Display_Message( PROGRAM_NAME, &
                            'Error inquiring the netCDF SRF file '//&
                            TRIM( Available_SRF_Filename(n) )//&
                            ' for frequency information.', &
                            Error_Status )
      STOP
    END IF


    ! -----------------------------
    ! Assign the file prefix string
    ! -----------------------------

    ProcessControl%File_Prefix(n) = TRIM( SensorInfo%Sensor_Id )


    ! --------------------------------------
    ! Determine the frequency interval index
    ! --------------------------------------

    Frequency_Interval_Loop: DO ch = 1, SensorInfo%n_Channels

      ! -- Compute the channel frequency interval 
      dF = ( End_SRF_Frequency(ch) - Begin_SRF_Frequency(ch) ) / &
      !    ---------------------------------------------------
               REAL( n_SRF_Frequencies(ch) - 1, fp_kind )

      ! -- Compute the frequency interval index
      Idx = Compute_dF_Index( dF )

      ! -- Is it valid?
      IF ( Idx < 0 ) THEN
        WRITE( Message, '( "Invalid frequency interval, ", es13.6, &
                          &"cm^-1, detected for channel ", i5, &
                          &" SRF from ", a, "." )' ) &
                        dF, &
                        SensorInfo%Sensor_Channel(ch), &
                        TRIM( Available_SRF_Filename(n) )
        CALL Display_Message( PROGRAM_NAME, &
                              TRIM( Message ), &
                              FAILURE )
        STOP
      END IF

      ! -- Save and compare the index
      IF ( ch == 1 ) THEN
        dF_Index = Idx
      ELSE
        IF ( Idx /= dF_Index ) THEN
          WRITE( Message, '( "Frequency interval, ", es13.6, &
                            &"cm^-1, for channel ", i5, &
                            &" is different from that for the other channels, ", es13.6, &
                            &"cm^-1, for ", a, "." )' ) &
                          FREQUENCY_INTERVAL( Idx ), &
                          SensorInfo%Sensor_Channel(ch), &
                          FREQUENCY_INTERVAL( dF_Index ), &
                          TRIM( Available_SRF_Filename(n) )
          CALL Display_Message( PROGRAM_NAME, &
                                TRIM( Message ), &
                                FAILURE )
          STOP
        END IF
      END IF

    END DO Frequency_Interval_Loop

    ! -- Assign the frequency interval index
    ProcessControl%dF_Index(n) = dF_Index
    

    ! ----------------------------------------
    ! Begin loop over channels for this sensor
    ! ----------------------------------------

    Valid_Channel = 0

    Channel_Loop: DO ch = 1, SensorInfo%n_Channels


      ! -------------------------------------------
      ! Only process current channel if it is valid
      ! -------------------------------------------

      IF ( ( Begin_SRF_Frequency(ch) >= FREQUENCY_BEGIN ) .AND. &
           (   End_SRF_Frequency(ch) <= FREQUENCY_END   )       ) THEN

        ! -- Update main channel counter index for ALL available sensors
        l = l + 1

        ! -- Update valid channel counter for CURRENT sensor
        Valid_Channel = Valid_Channel + 1

        ! -- Assign the begin and end VALID channel indices for CURRENT sensor
        IF ( Valid_Channel == 1 ) THEN
          ProcessControl%Channel_Index( 1, n ) = l
        END IF
        ProcessControl%Channel_Index( 2, n ) = l

        ! -- Assign the channel list data
        ProcessControl%List(l)%Channel       = SensorInfo%Sensor_Channel(ch)
        ProcessControl%List(l)%Begin_LBLband = Compute_LBL_band( Begin_SRF_Frequency(ch), &
                                                                 FREQUENCY_INTERVAL( ProcessControl%dF_Index(n) ) )
        ProcessControl%List(l)%End_LBLband   = Compute_LBL_band( End_SRF_Frequency(ch), &
                                                                 FREQUENCY_INTERVAL( ProcessControl%dF_Index(n) ) )

        ! -- Initialise processing flag
        ProcessControl%List(l)%Processed = 0

      END IF

    END DO Channel_Loop


    ! -----------------------------------
    ! Deallocate the SRF frequency arrays
    ! -----------------------------------

    DEALLOCATE( n_SRF_Frequencies, &
                Begin_SRF_Frequency, &
                End_SRF_Frequency, &
                STAT = Allocate_Status )

    IF ( Allocate_Status /= 0 ) THEN
      CALL Display_Message( PROGRAM_NAME, &
                            'Error deallocating frequency arrays for SRF netCDF file '//&
                            TRIM( Available_SRF_Filename(n) )//' read.', &
                            FAILURE )
      STOP
    END IF


    ! ----------------------------------------
    ! Destroy the current SensorInfo structure
    ! ----------------------------------------

    Error_Status = Destroy_SensorInfo( SensorInfo )

    IF ( Error_Status /= SUCCESS ) THEN
      WRITE( Message, '( "Error destroying SensorInfo for sensor # ", i5, &
                        &" in count loop." )' ) n
      CALL Display_Message( PROGRAM_NAME, &
                            TRIM( Message ), &
                            Error_Status )
      STOP
    END IF

  END DO Sensor_Read_Loop


  ! -----------------------------------------------------
  ! Update the total channel count. Some channels may not
  ! lie completely within the processing frequency bounds
  ! -----------------------------------------------------

  ProcessControl%n_Channels = l



  !#----------------------------------------------------------------------------#
  !#                   -- WRITE THE ProcessControl FILE --                      #
  !#----------------------------------------------------------------------------#

  ! ----------------
  ! Get the filename
  ! ----------------

  WRITE( *, FMT     = '( /5x, "Enter the Process Control output filename : " )', &
            ADVANCE = 'NO' )
  READ( *, FMT = '( a )' ) ProcessControl_Filename
  ProcessControl_Filename = ADJUSTL( ProcessControl_Filename )


  ! --------------
  ! Write the data
  ! --------------

  Error_Status = Write_ProcessControl( TRIM( ProcessControl_Filename ), &
                                       ProcessControl )

  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error writing Process Control data to '//&
                          TRIM( ProcessControl_Filename )//'.', &
                          Error_Status )
    STOP
  END IF



  !#----------------------------------------------------------------------------#
  !#                  -- DESTROY THE SensorInfo LINKED LIST --                  #
  !#----------------------------------------------------------------------------#

  Error_Status = Destroy_SensorInfo_List( SensorInfo_List )

  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error destroying SensorInfo linked list.', &
                          WARNING )
  END IF



  !#----------------------------------------------------------------------------#
  !#                   -- TEST READ OF ProcessControl FILE --                   #
  !#----------------------------------------------------------------------------#

  ! ------------------
  ! Read the data file
  ! ------------------

  Error_Status = Read_ProcessControl( TRIM( ProcessControl_Filename ), &
                                      ProcessControl )

  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error reading ProcessControl file '//&
                          TRIM( ProcessControl_Filename )//'.', &
                          FAILURE )
    STOP
  END IF


  ! ----------------
  ! Output some data
  ! ----------------

  WRITE( *, '( /5x, "SRF data file Process Control data:" )' )

  DO i = 1, ProcessControl%n_Files

    WRITE( *, '( 5x, a )' ) ProcessControl%File_Prefix( i )
    n = ProcessControl%Channel_Index(2,i) - ProcessControl%Channel_Index(1,i) + 1
    WRITE( *, '( 10x, "Number of channels: ", i4 )' ) n
    WRITE( *, '( 10x, "Channel indices:    ", i4, 2x, i4 )' ) &
              ProcessControl%Channel_Index(1,i), ProcessControl%Channel_Index(2,i) 

    WRITE( *, '( 10x, "Frequency interval index: ", i1 )' ) &
              ProcessControl%dF_Index(i)
    WRITE( *, '( 10x, "Frequency interval:       ", f6.4 )' ) &
              FREQUENCY_INTERVAL( ProcessControl%dF_Index(i) )

    DO l = ProcessControl%Channel_Index(1,i), ProcessControl%Channel_Index(2,i)

      WRITE( *, '( 15x, "CH: ", i4, ",    B1,B2: ",i3,1x,i3,",    FI:", i3 )' ) &
                ProcessControl%List(l)%Channel, &
                ProcessControl%List(l)%Begin_LBLband, ProcessControl%List(l)%End_LBLband, &
                ProcessControl%List(l)%File_Index

    END DO

  END DO


  ! ------------------------------------
  ! Destroy the ProcessControl structure
  ! ------------------------------------

  Error_Status = Destroy_ProcessControl( ProcessControl )

  IF ( Error_Status /= SUCCESS ) THEN
    CALL Display_Message( PROGRAM_NAME, &
                          'Error destroying ProcessControl data structure.', &
                          Error_Status )
    STOP
  END IF



  !#----------------------------------------------------------------------------#
  !#         -- CREATE A SIGNAL FILE INDICATING SUCCESSFUL COMPLETION --        #
  !#----------------------------------------------------------------------------#

  Error_Status = Create_Signal_File( TRIM( ProcessControl_Filename ) )

END PROGRAM Create_ProcessControl_File


!-------------------------------------------------------------------------------
!                          -- MODIFICATION HISTORY --
!-------------------------------------------------------------------------------
!
! $Id: Create_ProcessControl_File.f90,v 2.3 2006/06/30 16:47:16 dgroff Exp $
!
! $Date: 2006/06/30 16:47:16 $
!
! $Revision: 2.3 $
!
! $Name:  $
!
! $State: Exp $
!
! $Log: Create_ProcessControl_File.f90,v $
! Revision 2.3  2006/06/30 16:47:16  dgroff
! Changed "Error_Handler" references to "Message_Handler"
!
! Revision 2.2  2005/09/15 20:40:05  paulv
! - Renamed SRF frequency arrays to prevent namespace clash with USEd parameters.
! - Corrected calls to Compute_LBL_band.
!
! Revision 2.1  2005/05/15 23:31:35  paulv
! - Upgraded to Fortran-95.
! - All structure initialisation functions removed.
! - Modified to use new ProcessControl d0efinition and I/O modules.
! - Frequency interval index determined.
!
! Revision 2.0  2003/09/05 16:27:05  paulv
! - New version that uses a SensorInfo input file rather than a list of
!   SRF data files to read.
!
! Revision 1.6  2003/07/16 18:28:42  paulv
! - Ensured all the passed character strings were TRIMmed.
!
! Revision 1.5  2002/06/19 19:18:37  paulv
! - Extracting the sensor/platform ID from the SRF filename. Result is stored
!   in the PC%sensor_platform_ID pointer array.
!
! Revision 1.4  2002/06/07 20:57:30  paulv
! - Altered the method in which the channels were added to the Process Control
!   list. Previosuly all the channels were just added in. Now a check is
!   performed to ensure the channels are within the LBL band frequency limits.
!
! Revision 1.3  2002/06/07 17:10:20  paulv
! - Added documentation
! - Added signal file output.
!
! Revision 1.2  2002/05/30 20:38:16  paulv
! - Using new process control modules
!     Process_Control_Define and
!     Process_Control_IO
!   and their definitions/functions.
! - Altered the way the data was read in/manipulated to sync with the
!   new module methodology.
!
! Revision 1.1  2002/05/29 20:15:25  paulv
! Initial checkin.
!
!
!
!
