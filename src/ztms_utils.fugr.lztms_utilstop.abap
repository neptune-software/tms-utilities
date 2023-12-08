function-pool ztms_utils.                   "MESSAGE-ID ..
type-pools: stms.
* INCLUDE LZTMS_UTILSD...                    " Local class definition
types:
  begin of ty_transport_object,
             pgmid    type e071-pgmid,
             object   type e071-object,
             obj_name type e071-obj_name,
           end of  ty_transport_object .
TYPES: ty_t_transporT_objects TYPE STANDARD TABLE OF ty_transport_object WITH NON-UNIQUE DEFAULT KEY.

types: begin of ty_workflow_run,
         id                 type i,
         repository_id      type i,
         head_repository_id type i,
         head_branch        type string,
         head_sha           type string,
       end of ty_workflow_run,

       begin of ty_artifact,
         id                  type i,
         node_id             type string,
         name                type string,
         size_in_bytes       type i,
         url                 type string,
         archive_download_url type string,
         expired             type abap_bool,
         created_at          type string,
         updated_at          type string,
         expires_at          type string,
         workflow_run        type ty_workflow_run,
       end of ty_artifact,

       begin of ty_artifacts,
         total_count type i,
         artifacts   type standard table of ty_artifact with non-unique default key,
       end of ty_artifacts.
