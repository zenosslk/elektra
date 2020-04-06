import React, { useState, useEffect } from 'react';
import uniqueId from 'lodash/uniqueId'
import { Overlay, Popover, Tooltip } from 'react-bootstrap'
import Clipboard from 'react-clipboard.js';


/**
 * 
 * text --> text to show
 * size --> chars numbers to display
 * sliceType --> text sliced from END OR MIDDLE (default: END)
 * shouldClose --> Popover if displayed will be closed
 * bsClass --> overwrite base class
 * shouldCopy --> copy the given text. Default true
 * shouldPopover --> if text cut should show a popover with the original text. Default true
 */
const CopyPastePopover = ({text, size, sliceType, shouldClose, bsClass, shouldCopy, shouldPopover}) => {
  const [showTooltip, setShowTooltip] = useState(false)
  const [target, setTarget] = useState(null)
  const [showIcon, setShowIcon] = useState(false)
  const [showPopover, setShowPopover] = useState(false)
  const [popoverTarget, setPopoverTarget] = useState(null)
  let ref = React.useRef(null);
  const baseClass = bsClass || "cp"
  const shouldCopyText = shouldCopy == false ? false : true
  const shouldPopoverText = shouldPopover == false ? false : true
  let timeout = null
  const [windowScroll, setWindowScroll] = useState(false)

  useEffect(() => {
    if (shouldClose && showPopover) setShowPopover(false)
    if (windowScroll && showPopover) setShowPopover(false)
  },[shouldClose, windowScroll])

  useEffect(() => {
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  },[])

  const handleScroll = () => {
    if(timeout) return
    setWindowScroll(true)
    timeout = setTimeout(() => {
      timeout = null
      setWindowScroll(false)
    }, 1000 )
  }

  const onCopySuccess = () => {
    setShowTooltip(true)
    setTimeout(() => setShowTooltip(false),500)
  }

  const clipboard = <Clipboard ref={cb => {setTarget(cb)}} className="btn btn-link" data-clipboard-text={text} onSuccess={onCopySuccess}>
      <i className="fa fa-copy fa-fw"></i>
    </Clipboard>

  const tooltip = <Overlay
      show={showTooltip}
      placement="top"
      container={this}
      target={target}>
      <Tooltip id={uniqueId("copy-paste-tooltip-")}>Copied!</Tooltip>
    </Overlay>

  const popOver =  <Popover id={uniqueId("copy-paste-popover-")}>
    <div className="lbaas2">
        <span>{text}</span>
        {shouldCopyText &&
          <div className="text-right">
            {clipboard}
            {tooltip}
          </div>
        }
    </div>
  </Popover>

  const onMouseEnter = event => {
    if (showIcon) return 
    setShowIcon(true)
  }

  const onMouseLeave = event => {
    setShowIcon(false)
  }

  const handlePopoverClick = event => {
    setShowPopover(!showPopover)
    setPopoverTarget(event.target)
  }

  const textSliced = () => {
    if (sliceType && sliceType == "MIDDLE") {
      const first = size/2
      const second = size-first
      const firstPeace = text.slice(0,first)
      const secondPeace = text.slice(text.length-second,text.length)
      return [firstPeace, secondPeace]
    } 
    return [text.slice(0,size), ""]
  }

  const popoverOverlay = <React.Fragment>
    <a className='help-link' onClick={handlePopoverClick} href='javascript:void(0)'>
      <i className="fa fa-ellipsis-h"></i>
    </a>    
    <Overlay
      ref={r => (ref = r)} 
      onHide={() => setShowPopover(false)}
      show={showPopover}
      target={popoverTarget}
      placement="top"
      container={this}
      containerPadding={20}>
        {popOver}
    </Overlay>
  </React.Fragment>

  return ( 
    <React.Fragment>
      { text.length>size ?
        <div className={baseClass}>
          {shouldPopoverText ?
            <React.Fragment>
              <span>{textSliced()[0]}</span>
              <div className="cp-dots-help">
                {popoverOverlay}
              </div>
              <span>{textSliced()[1]}</span>
            </React.Fragment>
          :
          <span>{textSliced()[0]}...{textSliced()[1]}</span>
          }
        </div>
      :
        <span className={baseClass} onMouseEnter={onMouseEnter} onMouseLeave={onMouseLeave}>
          <span>
            {text}
            {showIcon && shouldCopyText &&
              <span className="copy-paste-icon">
                {clipboard}
                {tooltip}
              </span>
            }
          </span>
        </span>
      }
    </React.Fragment>
  );
}
 
export default CopyPastePopover;