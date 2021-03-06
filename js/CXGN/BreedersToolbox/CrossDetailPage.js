jQuery(document).ready(function() {    
    
    display_progeny(get_cross_id());
    
    get_properties(get_cross_id(), display_properties);
    
    function get_cross_id() { 
	var cross_id = jQuery('#cross_id').html();
	var regex = /\n|\r/g;
	
	cross_id = cross_id.replace(regex, "");
	return cross_id;

    }

    function get_cross_name() { 
	var cross_name = jQuery('#cross_name').html();
	var regex = /\n|\r/g;
	cross_name = cross_name.replace(regex, "");
	return cross_name;
    }
    
    function display_progeny(cross_id) { 
	
	jQuery.ajax( { 
	    type: 'POST',
	    url: '/cross/ajax/relationships/'+cross_id,
	    success: function(response) { 
		if (response.error) { 
		    alert(response.error);
		    return;
		}
		var html = "<table>";
		if (response.progeny) { 
		    for (var i=0; i<response.progeny.length; i++) { 
			html += '<td><a href="/stock/'+response.progeny[i][1]+'/view">'+response.progeny[i][0]+'</a></td></tr>';
		    }
		}						 
		html += "</table>";
		jQuery('#progeny_information_div').html(html);
		
		var parent_html = "";
		if (response.maternal_parent) { 
		    parent_html = '<img src="/img/Venus_symbol.svg" width="20" /> <a href="/stock/'+response.maternal_parent[1] +'/view">'+response.maternal_parent[0]+'</a><br />';
		}
		if (response.paternal_parent) { 						   
		    parent_html += '<img src="/img/Mars_symbol.svg" width="20" /> <a href="/stock/'+response.paternal_parent[1] +'/view">'+response.paternal_parent[0]+'</a><br />';						   }
		jQuery('#parents_information_div').html(parent_html);
	    },
	    
	    error: function(response, a, b) { 
		jQuery('#progeny_information_div').html('An error occurred. '+a +' '+ b);
	    }
	});
	
    }
    
    function display_parents(cross_id) { 
	jQuery.ajax( { 
	    type: 'POST',
	    url: '/cross/ajax/parents/'+cross_id,
	    success: function(response) { 
		if (response.error) { 
		    alert(response.error);
		    return;
		}
		var html = "<table>";
		if (response.parents) { 
		    for (var i=0; i<response.parents.length; i++) { 
			html += '<td><a href="/stock/'+response.parents[i][1]+'/view">'+response.parents[i][0]+'</a></td></tr>';
		    }
		}
		html += "</table>";
		jQuery('#parents_information_div').html(html);					   
	    },
	    error: function(response, a, b) { 
	  jQuery('#parents_information_div').html('An error occurred. '+a +' '+ b);
      }
	});
    }
    
    function display_properties(result) { 
	var props = result.props;
	var html = "";
	if (props) { 
	    html = "<table>";
	    for (var k in props) { 
		html += '<tr><td>'+k+'</td><td>&nbsp;</td>';
		var edit_link = "";					
		for (var n=0; n<props[k].length; n++) { 
		    html += '<td><b>'+props[k][n][0]+'</b></td><td>&nbsp;</td></tr>';
		}
	    }
    	    html += '</table>';
	    jQuery('#cross_properties_div').html(html);
	}
	else { 

	}
    }					 	
    
    jQuery('#add_more_progeny_link').click( function() { 
	jQuery('#add_more_progeny_dialog').dialog("open");
	jQuery('#progeny_count').focus();
    });
    
    jQuery('#add_more_progeny_dialog').dialog( { 
	height: 250,
	width: 500,
	buttons: { 'OK': 
		   {
		       id: 'add_more_progeny_dialog_ok_button', 
		       click: function() { 
			   jQuery('#working').dialog("open");
			   add_more_progeny(get_cross_id(), get_cross_name(), jQuery('#basename').val(), jQuery('#start_number').val(), jQuery('#progeny_count').val());
			   
		       },
		       text: "OK" 
		   } , 
		   'Cancel': {  
		       id: 'add_more_progeny_dialog_cancel_button',
		       click:  function() { jQuery('#add_more_progeny_dialog').dialog("close") }, 
		       text: "Cancel" } },
	autoOpen: false,
	title: 'Add more progeny'
    });
    
    function add_more_progeny(cross_id, cross_name, basename, start_number, progeny_count) { 
	
	jQuery.ajax({ 
	    url: '/cross/progeny/add/'+cross_id,
	    data: { 'cross_name': cross_name, 'basename': basename, 'start_number': start_number, 'progeny_count': progeny_count },
	    success: function(response) { 
		if (response.error) { 
		    alert(response.error); 
		}
		else { alert('Added '+progeny_count+' new progeny'); 
		       jQuery('#working').dialog("close");
                       display_progeny(get_cross_id());
		       jQuery('#add_more_progeny_dialog').dialog("close");
		     }
	    },
	    error: function(response, code, error) { alert('error: '+error); }
	});
    }

    jQuery('#edit_properties_dialog').dialog( { 
	height: 250,
	width: 500,
	buttons: {  
	    'Done': {  
		       id: 'edit_properties_dialog_done_button',
		       click:  function() { jQuery('#edit_properties_dialog').dialog("close") }, 
		       text: "Done" } 
	},
	autoOpen: false,
	title: 'Edit cross properties'
    });
    
    jQuery('#edit_properties_link').click( function() { 
	jQuery('#edit_properties_dialog').dialog("open");	
	get_properties(get_cross_id(), draw_properties_dialog);
    });
    
    
    jQuery('#property_submit').click( function() { 
	
	jQuery('#working').dialog("open");
	check_property(get_cross_id(), jQuery('#properties_select').val(), jQuery('#property_value').val());
	jQuery('#working').dialog("close");		           
    });


    function draw_properties_dialog(response) { 
	var type = jQuery('#properties_select').val();
	var prop = response.props[type];
	if (prop instanceof Array) { 
	    for (var n=0; n<prop.length; n++) { 
		jQuery('#property_value').val(prop[n][0]);
	    }
	}
	else { 
	    jQuery('#property_value').val('');
	}
    }

    jQuery('#properties_select').change( function() { 
	var value = jQuery('#properties_select').val();
	get_properties(get_cross_id(), draw_properties_dialog);
    });

    function set_properties_select(type) { 
	jQuery('#properties_select').val(type);	
    }

    function set_property_value(value) { 
	jQuery('#property_value').val(value);
    }
	    
    function get_properties(cross_id, callback) { 

	return jQuery.ajax( { 
	    type: 'GET',
	    url: '/cross/ajax/properties/'+cross_id,
	    success: callback,
	    error : error_callback
	});
    }

    function error_callback(a, b, c) { 
	alert("an error occurred "+c);
    }

    function check_property(cross_id, type, value) { 
	return jQuery.ajax( { 
	    url: '/cross/property/check/'+cross_id,
	    data: { 'cross_id' : cross_id, 'type': type, 'value': value }, 
	}).done( function(response) {
	    if (response.error) { alert(response.error); }
	    var yes;
	    if (response.message) { 
		yes = confirm(response.message + " Continue? "); 
		if (yes) { 
		    alert("Saving it.");
		    save_property(cross_id, type, value);
		}
		else { 
		    alert("Not saving.");
		}
	    }
	    if (response.success) { 
		save_property(cross_id, type, value);
	    }
	}).fail( function() { 
	    alert("The request for checking the parameters failed. Please try again.");
	});
    }

    function save_property(cross_id, type, value) { 
	return jQuery.ajax( { 
	    url: '/cross/property/save/'+cross_id,
	    data: { 'cross_id' : cross_id, 'type': type, 'value': value }

	}).done( function(response) { 
	    get_properties(get_cross_id(), display_properties);
	    save_confirm(response);

	    
	}).fail( function(response, x, y) { 
	    alert("An error occurred saving the property. "+y);
	});
    }
    
    function save_confirm(response) { 
	if (response.error) { 
	    alert(response.error);
	    return;
	}
	else { 
	    alert("The property was successfully saved.");
	}
    }
	
	
    

});
