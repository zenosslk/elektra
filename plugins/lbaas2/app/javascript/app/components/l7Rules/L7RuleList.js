import { useState, useEffect,useMemo } from 'react'
import {DefeatableLink} from 'lib/components/defeatable_link';
import useCommons from '../../../lib/hooks/useCommons'
import HelpPopover from '../shared/HelpPopover'
import useL7Rule from '../../../lib/hooks/useL7Rule';
import { useGlobalState } from '../StateProvider'
import { Table } from 'react-bootstrap'
import ErrorPage from '../ErrorPage';
import L7RuleListItem from './L7RuleListItem'
import { Tooltip, OverlayTrigger } from 'react-bootstrap';

const L7RulesList = ({props, loadbalancerID}) => {
  const {searchParamsToString} = useCommons()
  const {persistL7Rules} = useL7Rule()
  const listenerID = useGlobalState().listeners.selected
  const l7PolicyID = useGlobalState().l7policies.selected
  const state = useGlobalState().l7rules

  useEffect(() => {    
    initialLoad()
  }, [l7PolicyID]);

  const initialLoad = () => {
    if (l7PolicyID) {
      console.log("FETCH L7 RULES")
      persistL7Rules(loadbalancerID, listenerID, l7PolicyID, null).then((data) => {
      }).catch( error => {
      })
    }
  }

  const error = state.error
  const hasNext = state.hasNext
  const searchTerm = state.searchTerm
  const selected = state.selected
  const isLoading = state.isLoading
  const l7Rules = state.items

  return useMemo(() => {
    return ( 
      <React.Fragment>
        {l7PolicyID &&
          <React.Fragment>
            {error ?
              <div className="l7rules subtalbe multiple-subtable-right">
                <ErrorPage headTitle="L7 Rules" error={error} onReload={initialLoad}/>
              </div>
              :
              <div className="l7rules subtable multiple-subtable-right">
                <div className="display-flex multiple-subtable-padding-container">
                  <h4>L7 Rules</h4>
                  <HelpPopover text="An L7 Rule is a single, simple logical test which returns either true or false. It consists of a rule type, a comparison type, a value, and an optional key that gets used depending on the rule type. An L7 rule must always be associated with an L7 policy." />
                  <div className="btn-right">
                    {!selected &&
                      <DefeatableLink
                        disabled={isLoading}
                        to={`/loadbalancers/${loadbalancerID}/listeners/${listenerID}/l7policies/${l7PolicyID}/l7rules/new?${searchParamsToString(props)}`}
                        className='btn btn-primary btn-xs'>
                        New L7 Rule
                      </DefeatableLink>
                    }
                  </div>
                </div>
                
                <Table className={l7Rules.length>0 ? "table table-hover l7rules" : "table l7rules"} responsive>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>State/Prov. Status</th>
                            <th>Tags</th>
                            <th>
                              <div className="display-flex">
                              Type
                                <div className="margin-left">
                                <OverlayTrigger placement="top" overlay={<Tooltip id="defalult-pool-tooltip">Sorted by Type ASC</Tooltip>}>
                                  <i className="fa fa-sort-asc" />
                                </OverlayTrigger>  
                                </div>
                                /Compare Type
                              </div>
                            </th>
                            <th>Invert</th>
                            <th>Key</th>
                            <th>Value</th>
                            <th className='snug'></th>
                        </tr>
                    </thead>
                    <tbody>
                      {l7Rules && l7Rules.length>0 ?
                        l7Rules.map( (l7Rule, index) =>
                          <L7RuleListItem props={props} listenerID={listenerID} l7PolicyID={l7PolicyID} l7Rule={l7Rule} key={index}/>
                        )
                        :
                        <tr>
                          <td colSpan="10">
                            { isLoading ? <span className='spinner'/> : 'No L7 Rules found.' }
                          </td>
                        </tr>  
                      }
                    </tbody>
                  </Table>
              </div> 
            }
          </React.Fragment>
        }
      </React.Fragment>
    );
  } , [ l7PolicyID, JSON.stringify(l7Rules), error, selected, isLoading, searchTerm, props])
}
 
export default L7RulesList;