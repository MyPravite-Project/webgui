/* Import theme specific language pack */
 tinyMCE.importPluginLanguagePack('advimage','en,de,sv,zh_cn,cs');function TinyMCE_advimage_getInsertImageTemplate(){var template=new Array();template['file']='../../plugins/advimage/image.htm';template['width']=380;template['height']=380;template['width']+=tinyMCE.getLang('lang_insert_image_delta_width',0);template['height']+=tinyMCE.getLang('lang_insert_image_delta_height',0);return template;}