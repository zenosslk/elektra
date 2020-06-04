import React from 'react';
import { useDispatch } from '../../app/components/StateProvider'
import { ajaxHelper } from 'ajax_helper';

const useMember = () => {
  const dispatch = useDispatch()

  const fetchMembers = (lbID, poolID) => {
    return new Promise((handleSuccess,handleError) => {  
      ajaxHelper.get(`/loadbalancers/${lbID}/pools/${poolID}/members`).then((response) => {
        handleSuccess(response.data)
      })
      .catch( (error) => {
        handleError(error)
      })
    })
  }

  const persistMembers = (lbID, poolID) => {
    dispatch({type: 'RESET_MEMBERS'})
    dispatch({type: 'REQUEST_MEMBERS'})
    return new Promise((handleSuccess,handleError) => {
      fetchMembers(lbID, poolID).then((data) => {
        dispatch({type: 'RECEIVE_MEMBERS', items: data.members})
        handleSuccess(data)
      }).catch( error => {
        dispatch({type: 'REQUEST_MEMBERS_FAILURE', error: error})
        handleError(error.response)
      })
    })
  }

  const fetchServers = (lbID, poolID) => {
    return new Promise((handleSuccess,handleError) => {  
      ajaxHelper.get(`/loadbalancers/${lbID}/pools/${poolID}/members/servers_for_select`).then((response) => {
        handleSuccess(response.data)
      })
      .catch( (error) => {
        handleError(error.response)
      })
    })
  }

  const createMember = (lbID, poolID, values) => {
    return new Promise((handleSuccess,handleErrors) => {
      ajaxHelper.post(`/loadbalancers/${lbID}/pools/${poolID}/members`, { member: values }).then((response) => {
        dispatch({type: 'RECEIVE_MEMBER', member: response.data}) 
        handleSuccess(response)
      }).catch(error => {
        handleErrors(error)
      })
    })
  }

  return ({
    fetchMembers,
    persistMembers,
    fetchServers,
    createMember
  });
}
 
export default useMember;