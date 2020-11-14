/*
Mailchimp Ajax Submit
jQuery Plugin
Author: Siddharth Doshi

Use:
===
$('#form_id').ajaxchimp(options);

- Form should have one <input> element with attribute 'type=email'
- Form should have one label element with attribute 'for=email_input_id' (used to display error/success message)
- All options are optional.

Options:
=======
options = {
    language: 'en',
    callback: callbackFunction,
    url: 'http://blahblah.us1.list-manage.com/subscribe/post?u=5afsdhfuhdsiufdba6f8802&id=4djhfdsh99f'
}

Notes:
=====
To get the mailchimp JSONP url (undocumented), change 'post?' to 'post-json?' and add '&c=?' to the end.
For e.g. 'http://blahblah.us1.list-manage.com/subscribe/post-json?u=5afsdhfuhdsiufdba6f8802&id=4djhfdsh99f&c=?',
*/
!function(b){b.ajaxChimp={responses:{"We have sent you a confirmation email":0,"Please enter a value":1,"An email address must contain a single @":2,"The domain portion of the email address is invalid (the portion after the @: )":3,"The username portion of the email address is invalid (the portion before the @: )":4,"This email address looks fake or invalid. Please enter a real email address":5},translations:{en:null},init:function(a,c){b(a).ajaxChimp(c)}},b.fn.ajaxChimp=function(a){return b(this).each(function(h,e){var c=b(e),j=c.find("input[type=email]"),g=c.find("label[for="+j.attr("id")+"]"),d=b.extend({url:c.attr("action"),language:"en"},a),f=d.url.replace("/post?","/post-json?").concat("&c=?");c.attr("novalidate","true"),j.attr("name","EMAIL"),c.submit(function(){function i(q){if("success"===q.result){o="We have sent you a confirmation email",g.removeClass("error").addClass("valid"),j.removeClass("error").addClass("valid")}else{j.removeClass("valid").addClass("error"),g.removeClass("valid").addClass("error");var t=-1;try{var r=q.msg.split(" - ",2);if(void 0===r[1]){o=q.msg}else{var u=parseInt(r[0],10);u.toString()===r[0]?(t=r[0],o=r[1]):(t=-1,o=q.msg)}}catch(s){t=-1,o=q.msg}}"en"!==d.language&&void 0!==b.ajaxChimp.responses[o]&&b.ajaxChimp.translations&&b.ajaxChimp.translations[d.language]&&b.ajaxChimp.translations[d.language][b.ajaxChimp.responses[o]]&&(o=b.ajaxChimp.translations[d.language][b.ajaxChimp.responses[o]]),g.html(o),g.show(2000),d.callback&&d.callback(q)}var o,l={},k=c.serializeArray();b.each(k,function(m,n){l[n.name]=n.value}),b.ajax({url:f,data:l,success:i,dataType:"jsonp",error:function(m,n){console.log("mailchimp ajax submit error: "+n)}});var p="Submitting...";return"en"!==d.language&&b.ajaxChimp.translations&&b.ajaxChimp.translations[d.language]&&b.ajaxChimp.translations[d.language].submit&&(p=b.ajaxChimp.translations[d.language].submit),g.html(p).show(2000),!1})}),this}}(jQuery);