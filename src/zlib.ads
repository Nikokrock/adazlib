pragma Ada_2012;

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with System;

package Zlib is

   ZLIB_VERSION : aliased constant String := "1.2.11" & ASCII.NUL;
   Z_DEFLATED : constant := 8;  

   subtype Flush_Type is Integer range 0 .. 6;
   Z_NO_FLUSH      : constant Flush_Type := 0;
   Z_PARTIAL_FLUSH : constant Flush_Type := 1;
   Z_SYNC_FLUSH    : constant Flush_Type := 2;
   Z_FULL_FLUSH    : constant Flush_Type := 3;
   Z_FINISH        : constant Flush_Type := 4;
   Z_BLOCK         : constant Flush_Type := 5;
   Z_TREES         : constant Flush_Type := 6;

   subtype Status_Code is Integer range -6 .. 2;
   Z_OK            : constant Status_Code := 0;
   Z_STREAM_END    : constant Status_Code := 1;
   Z_NEED_DICT     : constant Status_Code := 2;
   Z_ERRNO         : constant Status_Code := -1;
   Z_STREAM_ERROR  : constant Status_Code := -2;
   Z_DATA_ERROR    : constant Status_Code := -3;
   Z_MEM_ERROR     : constant Status_Code := -4;
   Z_BUF_ERROR     : constant Status_Code := -5;
   Z_VERSION_ERROR : constant Status_Code := -6;

   subtype Compression_Level is Integer range -1 .. 9;
   Z_DEFAULT_COMPRESSION : constant Compression_Level := -1;
   Z_NO_COMPRESSION      : constant Compression_Level := 0; 
   Z_BEST_SPEED          : constant Compression_Level := 1;
   Z_BEST_COMPRESSION    : constant Compression_Level := 9;

   subtype Strategy_Type is Integer range 0 .. 4;
   Z_FILTERED         : constant := 1;  
   Z_HUFFMAN_ONLY     : constant := 2;  
   Z_RLE              : constant := 3;  
   Z_FIXED            : constant := 4;  
   Z_DEFAULT_STRATEGY : constant := 0;  

   subtype Data_Type is Integer range 0 .. 2;
   Z_BINARY  : constant Data_Type := 0;  
   Z_TEXT    : constant Data_Type := 1;  
   Z_ASCII   : constant Data_Type := Z_TEXT;
   Z_UNKNOWN : constant Data_Type := 2;

   Z_NULL : constant := 0;  

   type Allocate_Function is access function
      (Opaque : System.Address;
       Items  : Unsigned;
       Size   : Unsigned)
      return System.Address;
   pragma Convention (C, Allocate_Function);  

   type Free_Function is access procedure
      (Opaque  : System.Address;
       Address : System.Address);
   pragma Convention (C, Free_Function);  

   type Z_Stream is record
      next_in   : System.Address;
      avail_in  : unsigned;
      total_in  : unsigned_long;
      next_out  : System.Address;
      avail_out : unsigned;
      total_out : unsigned_long;
      msg       : Interfaces.C.Strings.chars_ptr;
      state     : System.Address;
      Z_Alloc   : Allocate_Function;
      Z_Free    : Free_Function;
      opaque    : System.Address;
      data_type : Integer;
      adler     : unsigned_long;
      reserved  : unsigned_long;
   end record;
   pragma Convention (C_Pass_By_Copy, Z_Stream);

   type Z_Stream_Access is access all Z_Stream;  

   type gz_header is record
      text : aliased int;  
      time : aliased unsigned_long;  
      xflags : aliased int;  
      os : aliased int;  
      extra : access unsigned_char;  
      extra_len : aliased unsigned;  
      extra_max : aliased unsigned;  
      name : access unsigned_char;  
      name_max : aliased unsigned;  
      comment : access unsigned_char;  
      comm_max : aliased unsigned;  
      hcrc : aliased int;  
      done : aliased int;  
   end record;
   pragma Convention (C_Pass_By_Copy, gz_header);

   type gz_headerp is access all gz_header;  

   function Get_Zlib_Version return Interfaces.C.Strings.chars_ptr;  
   pragma Import (C, Get_Zlib_Version, "zlibVersion");
   --  The application can compare zlibVersion and ZLIB_VERSION for consistency.
   --  If the first character differs, the library code actually used is not
   --  compatible with the zlib.h header file used by the application.  This check
   -- is automatically made by deflateInit and inflateInit.

   ---------------------------
   -- Compression Functions --
   ---------------------------

   function Deflate_Init
     (Stream      : in out Z_Stream;
      Level       : Compression_Level := Z_DEFAULT_COMPRESSION;
      version     : System.Address    := ZLIB_VERSION'Address;
      Stream_Size : Integer           := Z_Stream'Size) 
      return Integer;
   pragma Import (C, Deflate_Init, "deflateInit_");
   -- Initializes the internal stream state for compression.  The fields
   -- zalloc, zfree and opaque must be initialized before by the caller.  If
   -- zalloc and zfree are set to Z_NULL, deflateInit updates them to use default
   -- allocation functions.
   --
   -- The compression level must be Z_DEFAULT_COMPRESSION, or between 0 and 9:
   -- 1 gives best speed, 9 gives best compression, 0 gives no compression at all
   -- (the input data is simply copied a block at a time).  Z_DEFAULT_COMPRESSION
   -- requests a default compromise between speed and compression (currently
   -- equivalent to level 6).
   -- 
   -- deflateInit returns Z_OK if success, Z_MEM_ERROR if there was not enough
   -- memory, Z_STREAM_ERROR if level is not a valid compression level, or
   -- Z_VERSION_ERROR if the zlib library version (zlib_version) is incompatible
   -- with the version assumed by the caller (ZLIB_VERSION).  msg is set to null
   -- if there is no error message.  deflateInit does not perform any compression:
   -- this will be done by deflate().

   function Deflate
      (Stream : in out Z_Stream;
       Flush  : Flush_Type)
       return Status_Code;
   pragma Import (C, Deflate, "deflate");
   
   function Deflate_End (Stream : in out Z_Stream) return Status_Code;
   pragma Import (C, Deflate_End, "deflateEnd");

   -----------------------------------
   --  Main decompression functions --
   -----------------------------------

   function Inflate_Init
     (Stream      : in out Z_Stream;
      Version     : System.Address := ZLIB_VERSION'Address;
      Stream_Size : Integer := Z_Stream'Size) return int;  
   pragma Import (C, Inflate_Init, "inflateInit_");

   function Inflate (Stream : in out Z_Stream; Flush : Flush_Type) return Status_Code;
   pragma Import (C, Inflate, "inflate");

   function Inflate_End (Stream : in out Z_Stream) return Status_Code;
   pragma Import (C, Inflate_End, "inflateEnd");

   function Deflate_Set_Dictionary
     (Stream      : in out Z_Stream;
      Dictionary  : System.Address;
      Dict_Length : unsigned)
   return Status_Code;
   pragma Import (C, Deflate_Set_Dictionary, "deflateSetDictionary");

   function Deflate_Get_Dictionary
     (Stream      : in out Z_Stream;
      Dictionary  : System.Address;
      Dict_Length : out unsigned) return Status_Code;  
   pragma Import (C, Deflate_Get_Dictionary, "deflateGetDictionary");

   function deflateCopy (dest : Z_Stream_Access; source : Z_Stream_Access) return int;  
   pragma Import (C, deflateCopy, "deflateCopy");

   function deflateReset (strm : Z_Stream_Access) return int;  
   pragma Import (C, deflateReset, "deflateReset");

   function deflateParams
     (strm : Z_Stream_Access;
      level : int;
      strategy : int) return int;  
   pragma Import (C, deflateParams, "deflateParams");

   function deflateTune
     (strm : Z_Stream_Access;
      good_length : int;
      max_lazy : int;
      nice_length : int;
      max_chain : int) return int;  
   pragma Import (C, deflateTune, "deflateTune");

   function deflateBound (strm : Z_Stream_Access; sourceLen : unsigned_long) return unsigned_long;  
   pragma Import (C, deflateBound, "deflateBound");

   function deflatePending
     (strm : Z_Stream_Access;
      pending : access unsigned;
      bits : access int) return int;  
   pragma Import (C, deflatePending, "deflatePending");

   function deflatePrime
     (strm : Z_Stream_Access;
      bits : int;
      value : int) return int;  
   pragma Import (C, deflatePrime, "deflatePrime");

   function deflateSetHeader (strm : Z_Stream_Access; head : gz_headerp) return int;  
   pragma Import (C, deflateSetHeader, "deflateSetHeader");

   function inflateSetDictionary
     (strm : Z_Stream_Access;
      dictionary : access unsigned_char;
      dictLength : unsigned) return int;  
   pragma Import (C, inflateSetDictionary, "inflateSetDictionary");

   function inflateGetDictionary
     (strm : Z_Stream_Access;
      dictionary : access unsigned_char;
      dictLength : access unsigned) return int;  
   pragma Import (C, inflateGetDictionary, "inflateGetDictionary");

   function inflateSync (strm : Z_Stream_Access) return int;  
   pragma Import (C, inflateSync, "inflateSync");

   function inflateCopy (dest : Z_Stream_Access; source : Z_Stream_Access) return int;  
   pragma Import (C, inflateCopy, "inflateCopy");

   function inflateReset (strm : Z_Stream_Access) return int;  
   pragma Import (C, inflateReset, "inflateReset");

   function inflateReset2 (strm : Z_Stream_Access; windowBits : int) return int;  
   pragma Import (C, inflateReset2, "inflateReset2");

   function inflatePrime
     (strm : Z_Stream_Access;
      bits : int;
      value : int) return int;  
   pragma Import (C, inflatePrime, "inflatePrime");

   function inflateMark (strm : Z_Stream_Access) return long;  
   pragma Import (C, inflateMark, "inflateMark");

   function inflateGetHeader (strm : Z_Stream_Access; head : gz_headerp) return int;  
   pragma Import (C, inflateGetHeader, "inflateGetHeader");

   type in_func is access function (arg1 : System.Address; arg2 : System.Address) return unsigned;
   pragma Convention (C, in_func);  

   type out_func is access function
        (arg1 : System.Address;
         arg2 : access unsigned_char;
         arg3 : unsigned) return int;
   pragma Convention (C, out_func);  

   function inflateBack
     (strm : Z_Stream_Access;
      c_in : in_func;
      in_desc : System.Address;
      c_out : out_func;
      out_desc : System.Address) return int;  
   pragma Import (C, inflateBack, "inflateBack");

   function inflateBackEnd (strm : Z_Stream_Access) return int;  
   pragma Import (C, inflateBackEnd, "inflateBackEnd");

   function zlibCompileFlags return unsigned_long;  
   pragma Import (C, zlibCompileFlags, "zlibCompileFlags");

   function Compress
     (Dest       : System.Address;
      Dest_Len   : out unsigned_long;
      Source     : System.Address;
      Source_Len : unsigned_long)
      return Status_Code;
   pragma Import (C, Compress, "compress");

   function compress2
     (dest      : access unsigned_char;
      destLen   : access unsigned_long;
      source    : access unsigned_char;
      sourceLen : unsigned_long;
      level : int) return int;  
   pragma Import (C, compress2, "compress2");

   function Compress_Bound
      (Source_Length : unsigned_long)
      return unsigned_long;
   pragma Import (C, Compress_Bound, "compressBound");

   function uncompress
     (dest : access unsigned_char;
      destLen : access unsigned_long;
      source : access unsigned_char;
      sourceLen : unsigned_long) return int;  
   pragma Import (C, uncompress, "uncompress");

   function uncompress2
     (dest : access unsigned_char;
      destLen : access unsigned_long;
      source : access unsigned_char;
      sourceLen : access unsigned_long) return int;  
   pragma Import (C, uncompress2, "uncompress2");

   type gzFile is new System.Address;  

   function gzdopen (fd : int; mode : Interfaces.C.Strings.chars_ptr) return gzFile;  
   pragma Import (C, gzdopen, "gzdopen");

   function gzbuffer (file : gzFile; size : unsigned) return int;  
   pragma Import (C, gzbuffer, "gzbuffer");

   function gzsetparams
     (file : gzFile;
      level : int;
      strategy : int) return int;  
   pragma Import (C, gzsetparams, "gzsetparams");

   function gzread
     (file : gzFile;
      buf : System.Address;
      len : unsigned) return int;  
   pragma Import (C, gzread, "gzread");

   function gzfread
     (buf : System.Address;
      size : size_t;
      nitems : size_t;
      file : gzFile) return size_t;  
   pragma Import (C, gzfread, "gzfread");

   function gzwrite
     (file : gzFile;
      buf : System.Address;
      len : unsigned) return int;  
   pragma Import (C, gzwrite, "gzwrite");

   function gzfwrite
     (buf : System.Address;
      size : size_t;
      nitems : size_t;
      file : gzFile) return size_t;  
   pragma Import (C, gzfwrite, "gzfwrite");

   function gzprintf (file : gzFile; format : Interfaces.C.Strings.chars_ptr  -- , ...
      ) return int;  
   pragma Import (C, gzprintf, "gzprintf");

   function gzputs (file : gzFile; s : Interfaces.C.Strings.chars_ptr) return int;  
   pragma Import (C, gzputs, "gzputs");

   function gzgets
     (file : gzFile;
      buf : Interfaces.C.Strings.chars_ptr;
      len : int) return Interfaces.C.Strings.chars_ptr;  
   pragma Import (C, gzgets, "gzgets");

   function gzputc (file : gzFile; c : int) return int;  
   pragma Import (C, gzputc, "gzputc");

   function gzgetc (file : gzFile) return int;  
   pragma Import (C, gzgetc, "gzgetc");

   function gzungetc (c : int; file : gzFile) return int;  
   pragma Import (C, gzungetc, "gzungetc");

   function gzflush (file : gzFile; flush : int) return int;  
   pragma Import (C, gzflush, "gzflush");

   function gzrewind (file : gzFile) return int;  
   pragma Import (C, gzrewind, "gzrewind");

   function gzeof (file : gzFile) return int;  
   pragma Import (C, gzeof, "gzeof");

   function gzdirect (file : gzFile) return int;  
   pragma Import (C, gzdirect, "gzdirect");

   function gzclose (file : gzFile) return int;  
   pragma Import (C, gzclose, "gzclose");

   function gzclose_r (file : gzFile) return int;  
   pragma Import (C, gzclose_r, "gzclose_r");

   function gzclose_w (file : gzFile) return int;  
   pragma Import (C, gzclose_w, "gzclose_w");

   function gzerror (file : gzFile; errnum : access int) return Interfaces.C.Strings.chars_ptr;  
   pragma Import (C, gzerror, "gzerror");

   procedure gzclearerr (file : gzFile);  
   pragma Import (C, gzclearerr, "gzclearerr");

   function adler32
     (adler : unsigned_long;
      buf : access unsigned_char;
      len : unsigned) return unsigned_long;  
   pragma Import (C, adler32, "adler32");

   function adler32_z
     (adler : unsigned_long;
      buf : access unsigned_char;
      len : size_t) return unsigned_long;  
   pragma Import (C, adler32_z, "adler32_z");

   function crc32
     (crc : unsigned_long;
      buf : access unsigned_char;
      len : unsigned) return unsigned_long;  
   pragma Import (C, crc32, "crc32");

   function crc32_z
     (adler : unsigned_long;
      buf : access unsigned_char;
      len : size_t) return unsigned_long;  
   pragma Import (C, crc32_z, "crc32_z");

   function deflateInit2_u
     (strm : Z_Stream_Access;
      level : int;
      method : int;
      windowBits : int;
      memLevel : int;
      strategy : int;
      version : Interfaces.C.Strings.chars_ptr;
      stream_size : int) return int;  
   pragma Import (C, deflateInit2_u, "deflateInit2_");

   function inflateInit2_u
     (strm : Z_Stream_Access;
      windowBits : int;
      version : Interfaces.C.Strings.chars_ptr;
      stream_size : int) return int;  
   pragma Import (C, inflateInit2_u, "inflateInit2_");

   function inflateBackInit_u
     (strm : Z_Stream_Access;
      windowBits : int;
      window : access unsigned_char;
      version : Interfaces.C.Strings.chars_ptr;
      stream_size : int) return int;  
   pragma Import (C, inflateBackInit_u, "inflateBackInit_");

   subtype off_t is Long_Integer;

   type gzFile_s is record
      have : aliased unsigned;  
      next : access unsigned_char;  
      pos : aliased off_t;  
   end record;
   pragma Convention (C_Pass_By_Copy, gzFile_s);  

   function gzgetc_u (file : gzFile) return int;  
   pragma Import (C, gzgetc_u, "gzgetc_");

   function gzopen (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : Interfaces.C.Strings.chars_ptr) return gzFile;  
   pragma Import (C, gzopen, "gzopen");

   function gzseek
     (arg1 : gzFile;
      arg2 : off_t;
      arg3 : int) return off_t;  
   pragma Import (C, gzseek, "gzseek");

   function gztell (arg1 : gzFile) return off_t;  
   pragma Import (C, gztell, "gztell");

   function gzoffset (arg1 : gzFile) return off_t;  
   pragma Import (C, gzoffset, "gzoffset");

   function adler32_combine
     (arg1 : unsigned_long;
      arg2 : unsigned_long;
      arg3 : off_t) return unsigned_long;  
   pragma Import (C, adler32_combine, "adler32_combine");

   function crc32_combine
     (arg1 : unsigned_long;
      arg2 : unsigned_long;
      arg3 : off_t) return unsigned_long;  
   pragma Import (C, crc32_combine, "crc32_combine");

   function zError (arg1 : int) return Interfaces.C.Strings.chars_ptr;  
   pragma Import (C, zError, "zError");

   function inflateSyncPoint (arg1 : Z_Stream_Access) return int;  
   pragma Import (C, inflateSyncPoint, "inflateSyncPoint");

   function get_crc_table return access unsigned;  
   pragma Import (C, get_crc_table, "get_crc_table");

   function inflateUndermine (arg1 : Z_Stream_Access; arg2 : int) return int;  
   pragma Import (C, inflateUndermine, "inflateUndermine");

   function inflateValidate (arg1 : Z_Stream_Access; arg2 : int) return int;  
   pragma Import (C, inflateValidate, "inflateValidate");

   function inflateCodesUsed (arg1 : Z_Stream_Access) return unsigned_long;  
   pragma Import (C, inflateCodesUsed, "inflateCodesUsed");

   function inflateResetKeep (arg1 : Z_Stream_Access) return int;  
   pragma Import (C, inflateResetKeep, "inflateResetKeep");

   function deflateResetKeep (arg1 : Z_Stream_Access) return int;  
   pragma Import (C, deflateResetKeep, "deflateResetKeep");

   function gzvprintf
     (file : gzFile;
      format : Interfaces.C.Strings.chars_ptr;
      va : access System.Address) return int;  
   pragma Import (C, gzvprintf, "gzvprintf");

end Zlib;
