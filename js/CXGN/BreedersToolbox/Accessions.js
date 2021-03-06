/*jslint browser: true, devel: true */
/**

=head1 Accessions.js

Dialogs for managing accessions


=head1 AUTHOR

Jeremy D. Edwards <jde22@cornell.edu>

=cut

*/

var $j = jQuery.noConflict();

jQuery(document).ready(function ($) {

    var list = new CXGN.List();
    var accessionList;
    var doFuzzySearch;
    var validSpecies;

    function disable_ui() { 
	$('#working').dialog("open");
    }

    function enable_ui() { 
	$('#working').dialog("close");
    }

    function add_accessions(accessionsToAdd, speciesName) {
	var accessionsAsJSON = JSON.stringify(accessionsToAdd);
	$.ajax({
	    type: 'POST',
	    url: '/ajax/accession_list/add',
	    async: false,
	    dataType: "json",
	    timeout: 36000000,
	    data: {
		'accession_list': accessionsAsJSON,
		'species_name': speciesName,
	    },
	    beforeSend: function(){
		disable_ui();
            },  
	    success: function (response) {
		enable_ui();
		if (response.error) {
		    alert(response.error);
		} else {
		    alert("There were "+accessionsToAdd.length+" accessions added");
		}
	    },
	    error: function () {
		alert('An error occurred in processing. sorry');
	    }
	});
    }

    function verify_species_name() {
	var speciesName = $("#species_name_input").val();
	validSpecies = 0;
	$.ajax({
            type: 'GET',
            url: '/organism/verify_name',
	    dataType: "json",
            data: {
                'species_name': speciesName,
            },
            success: function (response) {
                if (response.error) {
                    alert(response.error);
		    validSpecies = 0;
                } else {
		    validSpecies = 1;
                }
            },
            error: function () {
                alert('An error occurred verifying species name. sorry');
		validSpecies = 0;
            }
	});
    }

    $('#species_name_input').change(function () {
        //verify_species_name();
    });

    $("#review_absent_dialog").dialog({
	autoOpen: false,	
	modal: true,
	autoResize:true,
        width: 500,
        position: ['top', 150],
	buttons: {
	    Add: function() {
		var speciesName = $("#species_name_input").val();
		var accessionsToAdd = accessionList;
		if (!speciesName) {
		    alert("Species name required");
		    return;
		}
		//if (validSpecies == 0){
		//    return;
		//}
		if (!accessionsToAdd || accessionsToAdd.length == 0) {
		    alert("No accessions to add");
		    return;
		}
		//alert("adding accessionsToAdd.length accessions");
		add_accessions(accessionsToAdd, speciesName);
		$(this).dialog( "close" );
		location.reload();
	    },
	    Close: function() {
		$(this).dialog( "close" );
	    },
	}
    });

    $("#review_found_matches_dialog").dialog({
	autoOpen: false,	
	modal: true,
	autoResize:true,
        width: 500,
        position: ['top', 150],
	buttons: {
	    Ok: function() {
		$(this).dialog( "close" );
	    },
	}
    });

    $("#review_fuzzy_matches_dialog").dialog({
	autoOpen: false,	
	modal: true,
	autoResize:true,
        width: 500,
        position: ['top', 150],
	buttons: {
	    Ok: function() {
		$(this).dialog( "close" );
	    },
	}
    });

    function review_verification_results(verifyResponse){
	var i;
	var j;

	if (verifyResponse.found) {
	    $('#count_of_found_accessions').html("Total number already in the database("+verifyResponse.found.length+")");
	    var found_html = '';
	    for( i=0; i < verifyResponse.found.length; i++){
		found_html = found_html 
		    +'<div class="left">'+verifyResponse.found[i].matched_string
		    +'</div>';
		if (verifyResponse.found[i].matched_string != verifyResponse.found[i].unique_name){
		    found_html = found_html 
			+'<div class="right">'
			+verifyResponse.found[i].unique_name
			+'</div>';
		}
	    }
	    $('#view_found_matches').html(found_html);

	    if (verifyResponse.fuzzy.length > 0 && doFuzzySearch) {
		$('#review_found_matches_dialog').bind('dialogclose', function() {
		    $('#review_fuzzy_matches_dialog').dialog('open');
		});
	    } else {
		$('#review_found_matches_dialog').bind('dialogclose', function() {
		    if (!accessionList || accessionList.length == 0) {
			alert("No accessions to add");
			location.reload();
		    } else {
			alert("Warning: use caution adding accessions.  Slight differences in spelling can cause undesired duplication.  Please send your list of accessions to add to a curator if you are unsure.");
			$('#review_absent_dialog').dialog('open');
		    }
		});
	    }

	    $('#review_found_matches_dialog').dialog('open');
	}

	if (verifyResponse.fuzzy) {
	    var fuzzy_html = '';
	    for( i=0; i < verifyResponse.fuzzy.length; i++) {
		fuzzy_html = fuzzy_html + '<div class="left">'+ verifyResponse.fuzzy[i].name + '</div>';
		fuzzy_html = fuzzy_html + '<div class="right"><select id ="fuzzyselect'+i+'">';
		for(j=0; j < verifyResponse.fuzzy[i].matches.length; j++){
		    fuzzy_html = fuzzy_html + '<option value="">' + verifyResponse.fuzzy[i].matches[j].name + '</option>';
		}
		fuzzy_html = fuzzy_html + '</select>';
	    }
	    fuzzy_html = fuzzy_html + '</div>';
	    $('#view_fuzzy_matches').html(fuzzy_html);
	    //$('#review_fuzzy_matches_dialog').dialog('open');

	    //Add to absent
	    for( i=0; i < verifyResponse.fuzzy.length; i++) {
		verifyResponse.absent.push(verifyResponse.fuzzy[i].name);
	    }
	    accessionList = verifyResponse.absent;

	    $('#review_fuzzy_matches_dialog').bind('dialogclose', function() {
		if (!accessionList || accessionList.length == 0) {
		    alert("No accessions to add");
		    location.reload();
		} else {
		    alert("Warning: use caution adding accessions.  Slight differences in spelling can cause undesired duplication.  Please send your list of accessions to add to a curator if you are unsure.");
		    $('#review_absent_dialog').dialog('open');
		}
	    });

	}

	if (verifyResponse.absent) {
	    $('#count_of_absent_accessions').html("Total number to be added("+verifyResponse.absent.length+")");
	    var absent_html = '';
	    $("#species_name_input").autocomplete({
		source: '/organism/autocomplete'
	    });
	    for( i=0; i < verifyResponse.absent.length; i++){
		absent_html = absent_html 
		    +'<div class="left">'+verifyResponse.absent[i]
		    +'</div>';
	    }
	    $('#view_absent').html(absent_html);
	    //$('#review_absent_dialog').dialog('open');
	}
    } 

    function verify_accession_list() {
	var accession_list_id = $('#accessions_list_select').val();
	var accession_list = JSON.stringify(list.getList(accession_list_id));
	doFuzzySearch = $('#fuzzy_check').attr('checked');
	//alert("should be disabled");
	//alert (doFuzzySearch);
	//alert(accession_list);
	


	$.ajax({
	    type: 'POST',
	    url: '/ajax/accession_list/verify',
	    timeout: 36000000,
	    //async: false,
	    dataType: "json",
	    data: {
                'accession_list': accession_list,
		//'do_fuzzy_search': doFuzzySearch,
	    },
	    beforeSend: function(){
		disable_ui();
            },  
            //complete : function(){
	    //enable_ui();
            //},  
	    success: function (response) {
		//enable_ui();
		enable_ui();
                if (response.error) {
		    alert(response.error);
                } else {
		    review_verification_results(response);
                }
	    },
	    error: function () {
		//enable_ui();
                alert('An error occurred in processing. sorry');
	    }
        });
    }

    $( "#add_accessions_dialog" ).dialog({
	autoOpen: false,
	modal: true,
	autoResize:true,
        width: 500,
        position: ['top', 150],
	buttons: {
	    Ok: function() {
		//disable_ui();
		verify_accession_list();
		$(this).dialog( "close" );
		//location.reload();
	    }
	}
    });

    $('#add_accessions_link').click(function () {
        $('#add_accessions_dialog').dialog("open");
	$("#list_div").html(list.listSelect("accessions"));
    });

    
});
